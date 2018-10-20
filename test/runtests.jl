global prev_theme=nothing

if haskey(ENV, "GADFLY_THEME")
    prev_theme = ENV["GADFLY_THEME"]
    pop!(ENV, "GADFLY_THEME")
end

using Test, Gadfly, Compat, LibGit2, Dates, Random, Compose, Cairo

if ispath(joinpath(@__DIR__,"..",".git"))
  repo = GitRepo(dirname(@__DIR__))
  branch = LibGit2.headname(repo)
  outputdir = joinpath(@__DIR__, mapreduce(x->startswith(branch,x), |, ["master","(detac"]) ?
          "master-output" : "devel-output")

  options = LibGit2.StatusOptions(flags=LibGit2.Consts.STATUS_OPT_INCLUDE_IGNORED |
                                        LibGit2.Consts.STATUS_OPT_RECURSE_IGNORED_DIRS)
  status = LibGit2.GitStatus(repo, status_opts=options)
  for i in 1:length(status)
      entry = status[i]
      index_to_workdir = unsafe_load(entry.index_to_workdir)
      if index_to_workdir.status == Int(LibGit2.Consts.DELTA_IGNORED)
          filepath = unsafe_string(index_to_workdir.new_file.path)
          startswith(filepath,joinpath("test",outputdir)) || continue
          rm(joinpath(dirname(@__DIR__),filepath))
      end
  end
  function mimic_git_log_n1(io::IO, head)
      hash = LibGit2.GitHash(head)
      println(io, "commit ",string(hash))
      commit = LibGit2.GitCommit(repo, hash)
      author = LibGit2.author(commit)
      println(io, "Author: ",author.name," <",author.email,">")
      datetime = unix2datetime(author.time + 60*author.time_offset)
      println(io, "Date:   ",Dates.format(datetime, "e u d HH:MM:SS YYYY"))
      println(io, "    ",LibGit2.message(commit))
      hash = commit = author = 0;  GC.gc()   # see https://github.com/JuliaLang/julia/issues/28306
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
      status = 0;  GC.gc()   # see https://github.com/JuliaLang/julia/issues/28306
  end
  head = LibGit2.head(repo)
  open(io->mimic_git_log_n1(io,head), joinpath(outputdir,"git.log"), "w")
  open(io->mimic_git_status(io,head), joinpath(outputdir,"git.status"), "w")
else
  outputdir = "master-output"
end

backends = Dict{AbstractString, Function}(
    "svg" => name -> SVG(joinpath(outputdir,"$(name).svg")),
    "svgjs" => name -> SVGJS(joinpath(outputdir,"$(name).js.svg"), jsmode=:linkabs),
    "png" => name -> PNG(joinpath(outputdir,"$(name).png")),
    "ps"  => name -> PS(joinpath(outputdir,"$(name).ps")),
    "pdf" => name -> PDF(joinpath(outputdir,"$(name).pdf")),
    "pgf" => name -> PGF(joinpath(outputdir,"$(name).tex"))
)

testdir = joinpath((@__DIR__),"testscripts")
testfiles = isempty(ARGS) ?
        [splitext(filename)[1] for filename in readdir(testdir) if filename[1]!='.'] :
        ARGS

@testset "Gadfly" begin
    for filename in testfiles
        Random.seed!(1)
        p = evalfile(joinpath(testdir, "$(filename).jl"))
        @test typeof(p) in [Plot,Compose.Context]
        for (backend_name, backend) in backends
            @info string(filename,'.',backend_name)
            r = draw(backend(filename), p)
            @test typeof(r) in [Bool,Nothing]
        end
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

if ispath(joinpath(@__DIR__,"..",".git"))
  repo = branch = options = status = head = 0;  GC.gc()   # see https://github.com/JuliaLang/julia/issues/28306
end
