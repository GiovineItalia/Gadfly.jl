
# Gadfly.weave implements a system for executable documentation, report
# generation, literate programming, and such.
# It works as follows:
#   1. Input is parsed by pandoc into JSON.
#   2. Weave executes the code blocks found in the JSON data, and inserts the
#      results back into the JSON representation.
#   3. This processed JSON representation is fed back into pandoc, and output in
#      the desired format.
#
# Pandoc's extensions to markdown are used to, e.g., tag code blocks as
# producing image data, or those that should not be executed.


export weave
import Base.parse


# A special module in which a documents code is executed.
module WeaveSandbox
    # Replace OUTPUT_STREAM references so we can capture output.
    OUTPUT_STREAM = IOString()
    print(x) = Base.print(OUTPUT_STREAM, x)
    println(x) = Base.println(OUTPUT_STREAM, x)

    # Output
    MIME_OUTPUT = Array(Tuple, 0)
    emit(mime, data) = push!(MIME_OUTPUT, (mime, data))
end


# Super-simple pandoc interface.
function pandoc(infn, infmt::String, outfmt::String, args::String...)
    cmd = ByteString["pandoc",
                     "--from=$(infmt)",
                     "--to=$(outfmt)"]
    for arg in args
        push!(cmd, arg)
    end

    readall(infn > Cmd(cmd))
end


# An iterator for the parse function: parsit(source) will iterate over the
# expressiosn in a string.
type ParseIt
    value::String
end

parseit(value::String) = ParseIt(value)
start(it::ParseIt) = 1
next(it::ParseIt, pos) = parse(it.value, pos)
done(it::ParseIt, pos) = pos > length(it.value)


# Execute an executable document.
#
# Code blocks within their own paragraph are executed, and their output is
# inserted into the document. This behavior is controlled by attributes assigned
# to the block.
#
# Args:
#   infn: Input filename.
#   infmt: Pandoc-compatible input format. E.g., markdown, rst, html, json, latex.
#   outfmt: Pandoc-compatibly output format.
#   pandoc_args: Extra arguments passed to pandoc.
#
# Returns:
#   A string in the requested output format,
#
function weave(infn::String, infmt::String, outfmt::String,
               pandoc_args::String...)
    selfcontained = any([pandoc_arg == "--self-contained"
                         for pandoc_arg in pandoc_args])

    # Substitute the default emitters for ones that simply print the image data.
    # Weave will detect the type of the data and embed it appropriately.
    for mime in ["image/svg+xml", "image/png", "image/gif", "image/jpeg",
                 "application/javascript"]
        Compose.emitters[mime] = data -> WeaveSandbox.emit(mime, data)
    end

    docname = match(r"^(.*)(\.[^\.]*)$", basename(infn)).captures[1]
    metadata, document = JSON.parse(pandoc(infn, infmt, "json"))

    # document is an array of singeton dictionaries. The one key gives the block
    # type, while the format of the value depends on the type.

    # Return a true/false for an attribute with the given default value.
    function attrib_bool(keyvals::Dict, key, default::Bool)
        haskey(keyvals, key) ? lowercase(strip(keyvals[key])) != "false" : default
    end

    processed_document = {}
    fignum = WeakRef(0)

    for block in document
        if !haskey(block, "CodeBlock")
            push!(processed_document, block)
            continue
        end

        # Process code blocks
        attribs, source = [v for v in values(block)][1]
        id, classes, keyvals = attribs
        classes = Set(classes...)
        keyvals = [k => v for (k,v) in keyvals]

        if !attrib_bool(keyvals, "execute", true)
            push!(processed_document, block)
            continue
        end

        # dispatch on the block type, defaulting to julia
        if contains(classes, "graphviz")
            mime, output = execblock_graphviz(source)
        elseif contains(classes, "latex")
            mime, output = execblock_latex(source)
        else
            mime, output = execblock_julia(source)
        end

        if !attrib_bool(keyvals, "hide", false)
            push!(processed_document, block)
        end

        push!(processed_document,
             process_output(mime, output, id, classes, keyvals,
                            outfmt, docname, fignum, selfcontained)...)
    end

    jsonout_path, jsonout = mktemp()
    JSON.print_to_json(jsonout, {metadata, processed_document})
    flush(jsonout)
    output = pandoc(jsonout_path, "json", outfmt, pandoc_args...)
    close(jsonout)
    rm(jsonout_path)
    output
end


# Detect data type.
#
# This is a sparse and crude version of the unix file command which takes a
# chunk of data and tries to figure out what it is. The only classification we
# need to do is between text, svg, and images types. Everything else is just
# binary noise which we should avoid outputting.
#
# Args:
#   data: Data with a type to be detected.
#
# Returns:
#   A mime type, or "binary" for unknown binary output.
#
function datatype(data::Vector{Uint8})
    const magic_numbers =
        [(Uint8['G', 'I', 'F', '8'], "image/gif"),
         (Uint8[0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a], "image/png"),
         (Uint8[0xff, 0xd8], "image/jpeg")]

    for (magic, mime) in magic_numbers
        if length(data) >= length(magic) && data[1:length(magic)] == magic
            return mime
        end
    end

    # Note: this falsely detects utf16 data as binary. Also, "binary" is not a
    # real mime type.
    if has(data, uint8('\0'))
        return "binary"
    end

    xml_magic = "<?xml"
    html_magic = "<!DOCTYPE html"
    if length(data) >= length(xml_magic) &&
       bytestring(data[1:length(xml_magic)]) == xml_magic &&
       !is(match(r"<svg", bytestring(data)), nothing)
        "image/svg+xml"
    elseif !is(match(r"^\s*<!DOCTYPE\s+html", bytestring(data)), nothing)
        "text/html"
    else
        "text/plain"
    end
end


# Generate JSON for the output of an executed code block.
#
# Args:
#   output: The output data.
#   id: ID of the code block.
#   classes: The set of classes assigned to the code block.
#   keyval: Dictionary of key/value attributes assigned to the code block.
#   docname: Name of the document.
#   fignum: Reference to a number for the next figure.
#   selfcontained: True if output should be inserted without generating any
#                  external files.
#
# Return:
#   An array of JSON elements that will be inserted directly after the code
#   block that was executed.
#
function process_output(mime::String, output::Vector{Uint8},
                        id::String, classes::Set, keyvals::Dict,
                        outfmt::String, docname::String, fignum::WeakRef,
                        selfcontained::Bool)

    if isempty(output)
        []
    elseif mime == "binary"
        warn("Skipping unknown binary data produced by a code block.")
        []
    elseif mime == "text/plain"
        [["CodeBlock" => {{"", {"julia_output"}, {}}, bytestring(output)}]]
    elseif mime == "application/javascript" || !is(match(r"^image", mime), nothing)
        fignum.value += 1

        figname = isempty(id) ? "fig_$(fignum.value)" : id
        if has(keyvals, "alt")
            caption = alttext = @sprintf("Figure %d: %s", fignum.value, keyvals["alt"])
        else
            alttext = "Figure $(fignum.value)"
            caption = ""
        end

        if selfcontained
            if mime == "image/svg+xml" && (outfmt == "html" || outfmt == "html5")
                # TODO: This works on firefox and safari, but is somewhat broken
                # on chrome. It seems to be a chrome bug, but I need to
                # investigate more.
                svgdata = bytestring(encode(Base64, output))
                [["RawBlock" =>
                    ["html",
                     "<figure>
                      <object alt=\"$(alttext)\" type=\"image/svg+xml\"
                              data=\"data:image/svg+xml;base64,$(svgdata)\">
                      </object>
                     </figure>"]]]
            elseif mime == "application/javascript"
                jsdata = bytestring(output)
                [["RawBlock" =>
                    ["html",
                     "<script type=\"text/javascript\">
                        $(jsdata)
                      </script>"]]]
            else
                # Let pandoc handle binary image formats.
                figfn, figio = mktemp()
                write(figio, output)
                close(figio)
                [["Para" => {["Image" => {{["Str" => alttext]}, {figfn, ""}}]}]]
            end
        else
            figext = ""
            if mime == "image/svg+xml"
                figext = "svg"
            elseif mime == "image/gif"
                figext = "gif"
            elseif mime == "image/png"
                figext = "png"
            elseif mime == "image/jpeg"
                figext = "jpg"
            elseif mime == "application/javascript"
                figext = "js"
            end

            figfn = "$(docname)_$(figname).$(figext)"
            figio = open(figfn, "w")
            write(figio, output)
            close(figio)
            figurl = figfn # TODO: support adding an absolute path

            if mime == "image/svg+xml" && (outfmt == "html" || outfmt == "html5")
                # SVG needs to be included using the object (or embed) tag for
                # embeded javascript to work.
                [["RawBlock" =>
                    ["html",
                     "<figure><object alt=\"$(alttext)\" \
                                      data=\"$(figurl)\" \
                                      type=\"image/svg+xml\"></object> \
                              <figcaption>$(caption)</figcaption></figure>"]]]
            elseif mime == "application/javascript"
                parent_id = string(figname, "_container")
                [["RawBlock" =>
                    ["html",
                        "<div id=\"$(parent_id)\"></div>
                         <script src=\"$(figurl)\"></script>
                         <script>draw(\"#$(parent_id)\");</script>"]]]
            else
                [["Para" => {["Image" => {{["Str" => alttext]}, {figurl, ""}}]}]]
            end
        end
    else
        error("Unknown mime type: ", mime)
    end
end


# Functions to process code blocks.


# Render graphviz code blocks and return the resulting SVG data.
function execblock_graphviz(source)
    input_path, input = mktemp()
    print(input, source)
    flush(input)
    seek(input, 0)
    output = readall(input > `dot -Tsvg`)
    close(input)
    rm(input_path)
    "image/svg+xml", output
end


# Render latex, convert to SVG with dvisvgm, and return the SVG data.
function execblock_latex(source)
    # latex -> dvi
    input_path, input = mktemp()
    print(input, source)
    flush(input)
    seek(input, 0)
    latexout_dir = mktempdir()
    run(`latex -output-format=dvi -output-directory=$(latexout_dir) $(input_path)` > SpawnNullStream())
    rm(input_path)

    # dvi -> svg
    latexout_path = "$(latexout_dir)/$(basename(input_path)).dvi"
    output = readall(`dvisvgm --stdout --no-fonts $(latexout_path)` .> SpawnNullStream())
    run(`rm -rf $(latexout_dir)`)

    "image/svg+xml", output
end


# Execute a block of julia code, capturing its output.
function execblock_julia(source)
    for expr in parseit(strip(source))
        result = eval(WeaveSandbox, expr)
        # TODO: If the echo attribute is set, find a way to insert the result
        #       of each expression.
    end

    if length(WeaveSandbox.MIME_OUTPUT) > 0
        mime, output = pop!(WeaveSandbox.MIME_OUTPUT)
        mime, convert(Vector{Uint8}, output)
    else
        seek(WeaveSandbox.OUTPUT_STREAM, 0)
        output = takebuf_array(WeaveSandbox.OUTPUT_STREAM)
        truncate(WeaveSandbox.OUTPUT_STREAM, 0)
        "text/plain", output
    end
end


