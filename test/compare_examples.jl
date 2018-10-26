include(joinpath(@__DIR__,"..","src","open_file.jl"))

using ArgParse, LibGit2

s = ArgParseSettings()
@add_arg_table s begin
    "--diff"
        help = "print to STDOUT the output of `diff`"
        action = :store_true
    "--two"
        help = "display both files"
        action = :store_true
    "--bw"
        help = "generate, save and display a B&W difference image for PNG and SVG files.  requires Rsvg, Cairo, and Images"
        action = :store_true
    "filter"
        help = "a regular expression describing the filenames to compare"
        default=""
end

args = parse_args(s)

if args["bw"]
    using Rsvg, Cairo, Images

    function svg2img(filename)
        r = Rsvg.handle_new_from_file(filename)
        d = Rsvg.handle_get_dimensions(r)
        cs = Cairo.CairoImageSurface(d.width,d.height,Cairo.FORMAT_ARGB32)
        c = Cairo.CairoContext(cs)
        Rsvg.handle_render_cairo(c,r)
        fout = tempname()
        Cairo.write_to_png(cs,fout)
        png = load(fout)
        rm(fout)
        png
    end
end

# delete diffedoutput/
repo = LibGit2.GitRepo(dirname(@__DIR__))
options = LibGit2.StatusOptions(flags=LibGit2.Consts.STATUS_OPT_INCLUDE_IGNORED |
                                      LibGit2.Consts.STATUS_OPT_RECURSE_IGNORED_DIRS)
status = LibGit2.GitStatus(repo, status_opts=options)
for i in 1:length(status)
    entry = status[i]
    entry.index_to_workdir == C_NULL && continue
    index_to_workdir = unsafe_load(entry.index_to_workdir)
    if index_to_workdir.status == Int(LibGit2.Consts.DELTA_IGNORED)
        filepath = unsafe_string(index_to_workdir.new_file.path)
        startswith(filepath,joinpath("test/diffed-output")) || continue
        rm(filepath)
    end
end

function display_two(master,devel)
    open_file(master)
    open_file(devel)
end

# Compare with cached output
masterout = joinpath((@__DIR__), "master-output")
develout  = joinpath((@__DIR__), "devel-output")
diffedout = joinpath((@__DIR__), "diffed-output")
ndifferentfiles = 0
const creator_producer = r"(Creator|Producer)"
filter_mkdir_git(x) = !mapreduce(y->x==y,|,[".mkdir","git.log","git.status"])
filter_regex(x) = occursin(Regex(args["filter"]), x)
master_files = filter(x->filter_mkdir_git(x) && filter_regex(x), readdir(masterout))
devel_files = filter(x->filter_mkdir_git(x) && filter_regex(x), readdir(develout))
cached_notin_genned = setdiff(master_files, devel_files)
isempty(cached_notin_genned) ||
      @warn string("files in master-output/ but not in devel-output/: ", join(cached_notin_genned,", "))
genned_notin_cached = setdiff(devel_files, master_files)
isempty(genned_notin_cached) ||
      @warn string("files in devel-output/ but not in master-output/: ", join(genned_notin_cached,", "))
for file in intersect(master_files,devel_files)
    print("Comparing ", file, " ... ")
    cached = open(readlines, joinpath(masterout, file))
    genned = open(readlines, joinpath(develout, file))
    same = length(cached) == length(genned)
    if same
        lsame = Bool[cached[i] == genned[i] for i = 1:length(cached)]
        if !all(lsame)
            for idx in findall(lsame.==false)
                # Don't worry about lines that are due to
                # Creator/Producer (e.g., Cairo versions)
                if findfirst(creator_producer, cached[idx]) !== nothing
                    lsame[idx] = true
                end
            end
        end
        same = same & all(lsame)
    end
    if same
        println("same!")
    else
        global ndifferentfiles
        ndifferentfiles +=1
        println("different :(")
        if args["diff"]
            diffcmd = `diff $(joinpath(masterout, file)) $(joinpath(develout, file))`
            run(ignorestatus(diffcmd))
        end
        args["two"] && display_two(joinpath(masterout,file), joinpath(develout,file))
        if args["bw"] && (endswith(file,".svg") || endswith(file,".png"))
            wait_for_user = false
            if endswith(file,".svg")
                gimg = svg2img(joinpath(develout,file));
                cimg = svg2img(joinpath(masterout,file));
            elseif endswith(file,".png")
                gimg = load(joinpath(develout,file));
                cimg = load(joinpath(masterout,file));
            end
            if size(gimg)==size(cimg)
                dimg = convert(Matrix{Gray}, gimg.==cimg)
                if any(dimg.==0)
                    fout = joinpath(diffedout,file*".png")
                    Images.save(fout, dimg)
                    wait_for_user = true
                    open_file("$fout")
                else
                    println("files are different but PNGs are the same")
                end
            else
                wait_for_user = true
                println("PNGs are different sizes :(")
            end
        end
        args["diff"] || args["two"] || (args["bw"] &&
                (endswith(file,".svg") || endswith(file,".png")) && wait_for_user) || continue
        println("Enter 'two' to display both files, nothing to continue, or press CTRL-C to quit")
        while true
          resp = readline()
          resp=="" && break
          resp=="two" && display_two(joinpath(masterout,file), joinpath(develout,file))
        end
    end
end

result = string("# different images = ",ndifferentfiles)
if ndifferentfiles==0
  @info result
else
  @warn result
end

repo = options = status = 0;  GC.gc()   # see https://github.com/JuliaLang/julia/issues/28306
