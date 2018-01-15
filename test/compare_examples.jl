using Base.Test, Rsvg, Cairo, Images

if !isempty(ARGS)
    regex_filter = Regex(ARGS[1])
end

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

# Compare with cached output
cachedout = joinpath((@__DIR__), "cachedoutput")
gennedout = joinpath((@__DIR__), "gennedoutput")
ndifferentfiles = 0
const creator_producer = r"(Creator|Producer)"
for file in filter(x->!startswith(x,"git."), readdir(cachedout))
    isdefined(:regex_filter) && !ismatch(regex_filter,file) && continue
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
        run(ignorestatus(`diff $(joinpath(cachedout, file)) $(joinpath(gennedout, file))`))
        run(`open $(joinpath(cachedout,file))`)
        run(`open $(joinpath(gennedout,file))`)
        if endswith(file,".svg")
            gimg = svg2img(joinpath(gennedout,file));
            cimg = svg2img(joinpath(cachedout,file));
        elseif endswith(file,".png")
            gimg = load(joinpath(gennedout,file));
            cimg = load(joinpath(cachedout,file));
        end
        if endswith(file,".svg") || endswith(file,".png")
            dimg = convert(Matrix{Gray}, gimg.==cimg)
            fout = joinpath(tempdir(),file*".png")
            Images.save(fout, dimg)
            run(`open $fout`)
        end
        println("Press the return/enter key to continue")
        readline()
        (endswith(file,".svg") || endswith(file,".png")) && rm(fout)
    end
end
@test ndifferentfiles==0
