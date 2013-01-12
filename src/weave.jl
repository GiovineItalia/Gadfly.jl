
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


# A special module in which a documents code is executed.
module WeaveSandbox
    # Replace OUTPUT_STREAM references so we can capture output.
    OUTPUT_STREAM = IOString()
    print(x) = Base.print(OUTPUT_STREAM, x)
    println(x) = Base.println(OUTPUT_STREAM, x)

    # A special SVG backend for compose to Write to our dummy OUTPUT_STREAM.
    # TODO: This is a kludge. Ideally we would avoid any Compose/Gadfly specific
    # hacks here. Think about a more general solution.
    import Compose
    import Compose.SVG
    function SVG(width::Compose.MeasureOrNumber, height::Compose.MeasureOrNumber)
        SVG(OUTPUT_STREAM, width, height)
    end
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
function next(it::ParseIt, pos)
    (expr, off) = parse(it.value[pos:])
    (expr, pos + off - 1)
end
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
#   A string in the requested output format.
#
function weave(infn::String, infmt::String, outfmt::String,
               pandoc_args::String...)
    docname = match(r"^(.*)(\.[^\.]*)$", basename(infn)).captures[1]
    metadata, document = JSON.parse(pandoc(infn, infmt, "json"))

    # document is an array of singeton dictionaries. The one key gives the block
    # type, while the format of the value depends on the type.

    # Return a true/false for an attribute with the given default value.
    function attrib_bool(keyvals::Dict, key, default::Bool)
        has(keyvals, key) ? lowercase(strip(keyvals[key])) != "false" : default
    end

    processed_document = {}
    fignum = 0

    for block in document
        if keys(block)[1] != "CodeBlock"
            push!(processed_document, block)
            continue
        end

        # Process code blocks
        attribs, source = values(block)[1]
        id, classes, keyvals = attribs
        classes = Set(classes...)
        keyvals = [k => v for (k,v) in keyvals]

        if !attrib_bool(keyvals, "execute", true)
            push!(processed_document, block)
            continue
        end

        if has(classes, "img")
            fignum += 1
        end

        # dispatch on the block type, defaulting to julia
        if has(classes, "graphviz")
            output = execblock_graphviz(source)
        elseif has(classes, "latex")
            output = execblock_latex(source)
        else
            output = execblock_julia(source)
        end

        if !attrib_bool(keyvals, "hide", false)
            push!(processed_document, block)
        end

        push!(processed_document,
             process_output(output, id, classes, keyvals, outfmt, docname, fignum)...)
    end

    jsonout_path, jsonout = mktemp()
    JSON.print_to_json(jsonout, {metadata, processed_document})
    flush(jsonout)
    #run(`cat $(jsonout_path)`)
    output = pandoc(jsonout_path, "json", outfmt, pandoc_args...)
    close(jsonout)
    rm(jsonout_path)
    output
end


# Generate JSON for the output of an executed code block.
#
# Args:
#   output: The output data.
#   id: ID of the code block.
#   classes: The set of classes assigned to the code block.
#   keyval: Dictionary of key/value attributes assigned to the code block.
#   docname: Name of the document.
#   fignum: Number for the next figure.
#
# Return:
#   An array of JSON elements that will be inserted directly after the code
#   block that was executed.
#
function process_output(output::String, id, classes, keyvals, outfmt, docname, fignum)
    if isempty(output)
        []
    elseif has(classes, "img")
        figname = isempty(id) ? "fig_$(fignum)" : id
        if has(keyvals, "alt")
            caption = alttext = @sprintf("Figure %d: %s", fignum, keyvals["alt"])
        else
            alttext = "Figure $(fignum)"
            caption = ""
        end
        figfn = "$(docname)_$(figname).svg" # TODO: handle non-svg images
        figio = open(figfn, "w")
        write(figio, output)
        close(figio)
        figurl = figfn # TODO: support adding an absolute path

        # TODO: support output other than SVG. We could inspect the file with
        # the unix file command, or maybe just classify it as SVG/not-SVG.

        if outfmt == "html" || outfmt == "html5"
            # SVG needs to be included using the object (or embed) tag for
            # embeded javascript to work.
            # TODO: captions
            [["RawBlock" =>
                ["html",
                 "<figure><object alt=\"$(alttext)\" \
                                  data=\"$(figurl)\" \
                                  type=\"image/svg+xml\"></object> \
                          <figcaption>$(caption)</figcaption></figure>"]]]
         else
            [["Para" => {["Image" => {{["Str" => alttext]}, {figurl, ""}}]}]]
        end
    else
        [["CodeBlock" => {{"", {"julia_output"}, {}}, output}]]
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
    output
end


# Render latex, convert to SVG with dvisvgm, and return the SVG data.
function execblock_latex(source)
    # latex -> dvi
    input_path, input = mktemp()
    print(input, source)
    flush(input)
    seek(input, 0)
    latexout_dir = mktempdir()
    run(`latex -output-format=dvi -output-directory=$(latexout_dir) $(input_path)` &> SpawnNullStream())
    rm(input_path)

    # dvi -> svg
    latexout_path = "$(latexout_dir)/$(basename(input_path)).dvi"
    output = readall(`dvisvgm --stdout --no-fonts $(latexout_path)` .> SpawnNullStream())
    run(`rm -rf $(latexout_dir)`)

    output
end


# Execute a block of julia code, capturing its output.
function execblock_julia(source)
    for expr in parseit(strip(source))
        result = eval(WeaveSandbox, expr)
        # TODO: If the echo attribute is set, find a way to insert the result
        #       of each expression.
    end

    output = bytestring(WeaveSandbox.OUTPUT_STREAM)
    seek(WeaveSandbox.OUTPUT_STREAM, 0)
    truncate(WeaveSandbox.OUTPUT_STREAM, 0)
    output
end


