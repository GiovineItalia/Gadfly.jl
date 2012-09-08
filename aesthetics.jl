
require("util.jl")
require("compose.jl")

# Aesthetics are parameterizations of the geometry of the plot

type Aesthetics
    x::Union(Nothing, Vector{Float64})
    y::Union(Nothing, Vector{Float64})
    xmin::Union(Nothing, Float64)
    xmax::Union(Nothing, Float64)
    ymin::Union(Nothing, Float64)
    ymax::Union(Nothing, Float64)
    xticks::Union(Nothing, Vector{Float64})
    yticks::Union(Nothing, Vector{Float64})
    size::Union(Nothing, Vector{Measure})
    color::Union(Nothing, Vector{Color})

    function Aesthetics()
        new(nothing, nothing, nothing,
            nothing, nothing, nothing,
            nothing, nothing, nothing,
            nothing)
        #new([nothing for _ in 1:length(Aesthetics.names)]...)
    end

    # shallow copy constructor
    function Aesthetics(a::Aesthetics)
        b = new()
        for name in Aesthetics.names
            setfield(b, name, getfield(a, name))
        end
        b
    end
end


copy(a::Aesthetics) = Aesthetics(a)


function json(a::Aesthetics)
    join([strcat(a, ":", json(getfield(a, var))) for var in aes_vars], ",\n")
end

