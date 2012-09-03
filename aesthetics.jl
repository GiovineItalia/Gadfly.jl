
require("util.jl")

# Aesthetics are parameterizations of the geometry of the plot

type Aesthetics
    x::Union(Nothing, Vector{Float64})
    y::Union(Nothing, Vector{Float64})

    function Aesthetics()
        new(nothing, nothing)
    end

    # shallow copy constructor
    function Aesthetics(a::Aesthetics)
        new(a.x, a.y)
    end
end


copy(a::Aesthetics) = Aesthetics(a)

