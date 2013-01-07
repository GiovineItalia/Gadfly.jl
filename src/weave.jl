
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
    using Gadfly
    using Compose

    # Replace OUTPUT_STREAM references so we can capture output.
    OUTPUT_STREAM = IOString()
    print(x) = Base.print(OUTPUT_STREAM, x)
    println(x) = Base.println(OUTPUT_STREAM, x)

    # Define Compose backend constructors that don't take a file orgument and
    # write to standard out. This lets us write, e.g.,
    #     draw(SVG(4inch, 4inch), my_plot)
    # and have it show up in the document.
    import Compose.SVG
    function SVG(width::Compose.MeasureOrNumber, height::Compose.MeasureOrNumber)
        SVG(OUTPUT_STREAM, width, height)
    end
end


# Super-simple pandoc interface.
function pandoc(io, infmt::String, outfmt::String, args::String...)
    cmd = ByteString["pandoc",
                     "--from=$(infmt)",
                     "--to=$(outfmt)"]
    for arg in args
        push(cmd, arg)
    end

    readall(io > Cmd(cmd))
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
#   input: Input stream in the format specified by infmt.
#   docname: A name given to the document. This is used mainly for naming output
#            files such an images.
#   infmt: Pandoc-compatible input format. E.g., markdown, rst, html, json, latex.
#   outfmt: Pandoc-compatibly output format.
#   pandoc_args: Extra arguments passed to pandoc.
#
# Returns:
#   A string in the requested output format.
#
function weave(input::IOStream, docname::String, infmt::String, outfmt::String,
               pandoc_args::String...)
    metadata, document = JSON.parse(pandoc(input, infmt, "json"))

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
            push(processed_document, block)
            continue
        end

        # Process code blocks
        attribs, source = values(block)[1]
        id, classes, keyvals = attribs
        classes = Set(classes...)
        keyvals = [k => v for (k,v) in keyvals]

        if !attrib_bool(keyvals, "execute", true)
            push(processed_document, block)
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
            push(processed_document, block)
        end

        push(processed_document,
             process_output(output, id, classes, keyvals, docname, fignum)...)
    end

    jsonout_path, jsonout = mktemp()
    JSON.print_to_json(jsonout, {metadata, processed_document})
    flush(jsonout)
    seek(jsonout, 0)
    output = pandoc(jsonout, "json", outfmt, pandoc_args...)
    close(jsonout)
    rm(jsonout_path)
    output
end


# Call weave taking the document name from the input file name.
function weave(input::String, infmt::String, outfmt::String,
               pandoc_args::String...)
    docname = match(r"^(.*)(\.[^\.]*)$", basename(input)).captures[1]
    io = open(input)
    output = weave(io, docname, infmt, outfmt, pandoc_args...)
    close(io)
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
function process_output(output::String, id, classes, keyvals, docname, fignum)
    if isempty(output)
        []
    elseif has(classes, "img")
        figname = isempty(id) ? "fig_$(fignum)" : id
        if has(keyvals, "alt")
            alttext = @sprintf("Figure %d: %s", fignum, keyvals["alt"])
        else
            alttext = "Figure $(fignum)"
        end
        figfn = "$(docname)_$(figname).svg" # TODO: handle non-svg images
        figio = open(figfn, "w")
        write(figio, output)
        close(figio)
        figurl = figfn # TODO: support adding an absolute path
        [["Para" => {["Image" => {{["Str" => alttext]}, {figurl, ""}}]}]]
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
    run(`latex -output-format=dvi -output-directory=$(latexout_dir) $(input_path)` &> "/dev/null")
    rm(input_path)

    # dvi -> svg
    latexout_path = "$(latexout_dir)/$(basename(input_path)).dvi"
    output = readall(`dvisvgm --stdout --no-fonts $(latexout_path)` .> "/dev/null")
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


