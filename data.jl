
require("data.jl")

# The Data type represents bindings of data to aesthetics.

type Data
    x::Union(Nothing, AbstractArray)
    y::Union(Nothing, AbstractArray)

    function Data()
        new(nothing, nothing)
    end

    # shallow copy constructor
    function Data(a::Data)
        new(a.x, a.y)
    end
end


copy(a::Data) = Data(a)

