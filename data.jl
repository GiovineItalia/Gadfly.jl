
require("aesthetics.jl")
require("iterators.jl")

import Iterators.*

# The Data type represents bindings of data to aesthetics.

#@eval begin
    #type Data
        #$()
    #end
#end

# TODO: generate this with a macro

type Data
    x
    y
    xticks
    yticks
    size
    color

    function Data()
        new(nothing, nothing, nothing, nothing, nothing, nothing)
    end

    # shallow copy constructor
    function Data(a::Data)
        b = new()
        for name in Data.names
            setfield(b, name, getfield(a, name))
        end
        b
    end
end

copy(a::Data) = Data(a)


function chain(ds::Data...)
    chained_data = Data()
    for name in Data.names
        vs = {getfield(d, name) for d in ds}
        vs = {v for v in filter(issomething, vs)}
        if isempty(vs)
            setfield(chained_data, name, nothing)
        else
            setfield(chained_data, name, chain(vs...))
        end
    end

    chained_data
end

