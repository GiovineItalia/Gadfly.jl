using Base.Test, Compat

# Compare with cached output
cachedout = joinpath((@compat @__DIR__), "cachedoutput")
gennedout = joinpath((@compat @__DIR__), "gennedoutput")
ndifferentfiles = 0
const creator_producer = r"(Creator|Producer)"
for file in readdir(cachedout)
    cached = open(readlines, joinpath(cachedout, file))
    genned = open(readlines, joinpath(gennedout, file))
    same = (n=length(cached)) == length(genned)
    if same
        lsame = Bool[cached[i] == genned[i] for i = 1:n]
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
    if !same
        ndifferentfiles +=1
        println(string(file, " differs:\n", readstring(ignorestatus(
                `diff $(joinpath(cachedout, file)) $(joinpath(gennedout, file))`))))
        run(`open $(joinpath(cachedout,file))`)
        run(`open $(joinpath(gennedout,file))`)
        println("Press the return/enter key to continue")
        readline()
    end
end
@test ndifferentfiles==0
