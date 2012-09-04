
require("util.jl")
require("compose.jl")

# Aesthetics are parameterizations of the geometry of the plot

type Aesthetics
    x::Union(Nothing, Vector{Float64})
    y::Union(Nothing, Vector{Float64})
    xticks::Union(Nothing, Vector{Float64})
    yticks::Union(Nothing, Vector{Float64})
    size::Union(Nothing, Vector{Measure})
    color::Union(Nothing, Vector{Color})

    function Aesthetics()
        new([nothing for _ in 1:length(Aesthetics.names)]...)
    end

    # shallow copy constructor
    function Aesthetics(a::Aesthetics)
        new(a.x, a.y, a.xticks, a.yticks, a.size, a.color)
    end
end


copy(a::Aesthetics) = Aesthetics(a)


function json(a::Aesthetics)
    join([strcat(a, ":", json(getfield(a, var))) for var in aes_vars], ",\n")
end
