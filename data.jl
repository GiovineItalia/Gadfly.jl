
require("aesthetics.jl")

# The Data type represents bindings of data to aesthetics.

#@eval begin
    #type Data
        #$()
    #end
#end

# TODO: generate this with a macro

type Data
    x::Union(Nothing, AbstractArray)
    y::Union(Nothing, AbstractArray)
    xticks::Union(Nothing, AbstractArray)
    yticks::Union(Nothing, AbstractArray)
    size::Union(Nothing, AbstractArray)
    color::Union(Nothing, AbstractArray)

    function Data()
        new(nothing, nothing)
    end

    # shallow copy constructor
    function Data(a::Data)
        new(a.x, a.y)
    end
end


copy(a::Data) = Data(a)

