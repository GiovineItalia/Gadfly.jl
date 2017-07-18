global prev_theme=nothing

if haskey(ENV, "GADFLY_THEME")
    prev_theme = ENV["GADFLY_THEME"]
    pop!(ENV, "GADFLY_THEME")
end

using Gadfly, Compat, Base.LibGit2

repo = GitRepo(dirname(@compat @__DIR__))
outputdir = in(LibGit2.headname(repo)[1:6], ["master","(detac"]) ? "cachedoutput" : "gennedoutput"

run(pipeline(`git log -n 1`,joinpath(outputdir,".log")))
run(pipeline(`git status`,joinpath(outputdir,".status")))

backends = @compat Dict{AbstractString, Function}(
    "svg" => (name, width, height) -> SVG(joinpath(outputdir,"$(name).svg"), width, height),
    "svgjs" => (name, width, height) -> SVGJS(joinpath(outputdir,"$(name).js.svg"), width, height, jsmode=:linkabs),
    "png" => (name, width, height) -> PNG(joinpath(outputdir,"$(name).png"), width, height),
    #"ps"  => (name, width, height) -> PS(joinpath(outputdir,"$(name).ps"),   width, height),
    #"pdf" => (name, width, height) -> PDF(joinpath(outputdir,"$(name).pdf"), width, height)
    "pgf" => (name, width, height) -> PGF(joinpath(outputdir,"$(name).tex"), width, height)
)

testdir = joinpath((@compat @__DIR__),"testscripts")
testfiles = isempty(ARGS) ? [splitext(filename)[1] for filename in readdir(testdir)] : ARGS

for filename in testfiles, (backend_name, backend) in backends
    startswith(filename,'.') && continue
    println(STDERR, "Rendering $(filename) on $(backend_name) backend.")
    try
        srand(1)
        p = evalfile(joinpath(testdir, "$(filename).jl"))
        width = Compose.default_graphic_width
        height = Compose.default_graphic_height
        @time eval(Expr(:call, ()->draw(backend(filename, width, height), p) ))
    catch
        println(STDERR, "FAILED!")
        rethrow()
    end
end

output = open(string(outputdir,".html"), "w")
print(output,
    """
    <!DOCTYPE html>
    <html>
    <meta charset="utf-8" />
    <head>
        <title>Gadfly Test Plots</title>
    </head>
    <body>
    <script src="$(Compose.snapsvgjs)"></script>
    <script src="$(Gadfly.gadflyjs)"></script>
    <div style="width:900; margin:auto; text-align: center; font-family: sans-serif; font-size: 20pt;">
    """)

for filename in testfiles
    println(output, "<p>", filename, "</p>")
    print(output, """<div id="$(filename)"><object type="image/svg+xml" data="$(outputdir)/$(filename).js.svg"></object></div>""")
    print(output, """<img width="450px" src="$(outputdir)/$(filename).svg">""")
    print(output, """<img width="450px" src="$(outputdir)/$(filename).png">\n""")
end

print(output,
    """
    </div>
    </body>
    """)

close(output)

if prev_theme !== nothing
    ENV["GADFLY_THEME"] = prev_theme
end

if !haskey(ENV, "TRAVIS") &&
            !isempty(readdir(joinpath((@compat @__DIR__),"cachedoutput"))) &&
            !isempty(readdir(joinpath((@compat @__DIR__),"gennedoutput")))
    include("compare_examples.jl")
end
