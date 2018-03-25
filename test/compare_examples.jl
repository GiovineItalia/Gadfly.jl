using ArgParse

s = ArgParseSettings()
@add_arg_table s begin
    "--diff"
        help = "print to STDOUT the output of `diff`"
        action = :store_true
    "--two"
        help = "open and display both files"
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
    index_to_workdir = unsafe_load(entry.index_to_workdir)
    if index_to_workdir.status == Int(LibGit2.Consts.DELTA_IGNORED)
        filepath = unsafe_string(index_to_workdir.new_file.path)
        startswith(filepath,joinpath("test/diffedoutput")) || continue
        rm(filepath)
    end
end

# Compare with cached output
cachedout = joinpath((@__DIR__), "cachedoutput")
gennedout = joinpath((@__DIR__), "gennedoutput")
diffedout = joinpath((@__DIR__), "diffedoutput")
ndifferentfiles = 0
const creator_producer = r"(Creator|Producer)"
filter_mkdir_git(x) = !mapreduce(y->x==y,|,[".mkdir","git.log","git.status"])
filter_regex(x) = ismatch(Regex(args["filter"]), x)
cached_files = filter(x->filter_mkdir_git(x) && filter_regex(x), readdir(cachedout))
genned_files = filter(x->filter_mkdir_git(x) && filter_regex(x), readdir(gennedout))
cached_notin_genned = setdiff(cached_files, genned_files)
isempty(cached_notin_genned) ||
      warn("files in cachedoutput/ but not in gennedoutput/: ", join(cached_notin_genned,", "))
genned_notin_cached = setdiff(genned_files, cached_files)
isempty(genned_notin_cached) ||
      warn("files in gennedoutput/ but not in cachedoutput/: ", join(genned_notin_cached,", "))
for file in intersect(cached_files,genned_files)
    print("Comparing ", file, " ... ")
    cached = open(readlines, joinpath(cachedout, file))
    genned = open(readlines, joinpath(gennedout, file))
    same = length(cached) == length(genned)
    if same
        lsame = Bool[cached[i] == genned[i] for i = 1:length(cached)]
        if !all(lsame)
            for idx in find(lsame.==false)
                # Don't worry about lines that are due to
                # Creator/Producer (e.g., Cairo versions)
                if !isempty(search(cached[idx], creator_producer))
                    lsame[idx] = true
                end
            end
        end
        same = same & all(lsame)
    end
    if same
        println("same!")
    else
        ndifferentfiles +=1
        println("different :(")
        if args["diff"]
            diffcmd = `diff $(joinpath(cachedout, file)) $(joinpath(gennedout, file))`
            run(ignorestatus(diffcmd))
        end
        if args["two"]
            run(`open $(joinpath(cachedout,file))`)
            run(`open $(joinpath(gennedout,file))`)
        end
        if args["bw"] && (endswith(file,".svg") || endswith(file,".png"))
            wait_for_user = false
            if endswith(file,".svg")
                gimg = svg2img(joinpath(gennedout,file));
                cimg = svg2img(joinpath(cachedout,file));
            elseif endswith(file,".png")
                gimg = load(joinpath(gennedout,file));
                cimg = load(joinpath(cachedout,file));
            end
            if size(gimg)==size(cimg)
                dimg = convert(Matrix{Gray}, gimg.==cimg)
                if any(dimg.==0)
                    fout = joinpath(diffedout,file*".png")
                    Images.save(fout, dimg)
                    wait_for_user = true
                    run(`open $fout`)
                else
                    println("files are different but PNGs are the same")
                end
            else
                wait_for_user = true
                println("PNGs are different sizes :(")
            end
        end
        args["diff"] || args["two"] || (args["bw"] && wait_for_user) || continue
        println("Press ENTER to continue, CTRL-C to quit")
        readline()
    end
end

infoorwarn = ndifferentfiles==0 ? info : warn
infoorwarn("# different images = ",ndifferentfiles)
