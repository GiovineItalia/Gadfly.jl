global prev_theme=nothing

if haskey(ENV, "GADFLY_THEME")
    prev_theme = ENV["GADFLY_THEME"]
    pop!(ENV, "GADFLY_THEME")
end

using Gadfly, Compat

repo = LibGit2.GitRepo(dirname(@__DIR__))
branch = LibGit2.headname(repo)
outputdir = mapreduce(x->startswith(branch,x), |, ["master","(detac"]) ?
        "cachedoutput" : "gennedoutput"

if VERSION>=v"0.6"
    function mimic_git_log_n1(io::IO, head)
        hash = LibGit2.GitHash(head)
        println(io, "commit ",string(hash))
        commit = LibGit2.GitCommit(repo, hash)
        author = LibGit2.author(commit)
        println(io, "Author: ",author.name," <",author.email,">")
        datetime = Dates.unix2datetime(author.time + 60*author.time_offset)
        println(io, "Date:   ",Dates.format(datetime, "e u d HH:MM:SS YYYY"))
        println(io, "    ",LibGit2.message(commit))
    end

    function mimic_git_status(io::IO, head)
        println(io, "On branch ",LibGit2.shortname(head))
        status = LibGit2.GitStatus(repo)
        println(io, "Changes not staged for commit:")
        for i in 1:length(status)
            entry = status[i]
            index_to_workdir = unsafe_load(entry.index_to_workdir)
            if index_to_workdir.status == Int(LibGit2.Consts.DELTA_MODIFIED)
                println(io, "    ", unsafe_string(index_to_workdir.new_file.path))
            end
        end
        println(io, "Untracked files:")
        for i in 1:length(status)
            entry = status[i]
            index_to_workdir = unsafe_load(entry.index_to_workdir)
            if index_to_workdir.status == Int(LibGit2.Consts.DELTA_UNTRACKED)
                println(io, "    ", unsafe_string(index_to_workdir.new_file.path))
            end
        end
    end

    head = LibGit2.head(repo)
    open(io->mimic_git_log_n1(io,head), joinpath(outputdir,"git.log"), "w")
    open(io->mimic_git_status(io,head), joinpath(outputdir,"git.status"), "w")
end

backends = Dict{AbstractString, Function}(
    "svg" => (name, width, height) -> SVG(joinpath(outputdir,"$(name).svg"), width, height),
    "svgjs" => (name, width, height) -> SVGJS(joinpath(outputdir,"$(name).js.svg"), width, height, jsmode=:linkabs),
    "png" => (name, width, height) -> PNG(joinpath(outputdir,"$(name).png"), width, height),
    #"ps"  => (name, width, height) -> PS(joinpath(outputdir,"$(name).ps"),   width, height),
    #"pdf" => (name, width, height) -> PDF(joinpath(outputdir,"$(name).pdf"), width, height)
    "pgf" => (name, width, height) -> PGF(joinpath(outputdir,"$(name).tex"), width, height)
)

testdir = joinpath((@__DIR__),"testscripts")
testfiles = isempty(ARGS) ?
        [splitext(filename)[1] for filename in readdir(testdir) if filename[1]!='.'] :
        ARGS

for filename in testfiles, (backend_name, backend) in backends
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

if !haskey(ENV, "TRAVIS") && !isinteractive() &&
            !isempty(readdir(joinpath((@__DIR__),"cachedoutput"))) &&
            !isempty(readdir(joinpath((@__DIR__),"gennedoutput")))
    run(`$(Base.julia_cmd()) compare_examples.jl`)
end
