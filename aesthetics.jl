
require("util.jl")
require("compose.jl")

# Aesthetics are parameterizations of the geometry of the plot

type Aesthetics
    x::Union(Nothing, Vector{Float64})
    y::Union(Nothing, Vector{Float64})
    size::Union(Nothing, Vector{Measure})
    color::Union(Nothing, Vector{Color})

    function Aesthetics()
        new(nothing, nothing, nothing, nothing)
    end

    # shallow copy constructor
    function Aesthetics(a::Aesthetics)
        new(a.x, a.y, a.size, a.color)
    end
end


copy(a::Aesthetics) = Aesthetics(a)

