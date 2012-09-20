
require("misc.jl")
require("compose.jl")

# Aesthetics are parameterizations of the geometry of the plot

type Aesthetics
    x::Union(Nothing, Vector{Float64})
    y::Union(Nothing, Vector{Float64})
    xtick::Union(Nothing, Vector{Float64})
    ytick::Union(Nothing, Vector{Float64})
    xtick_labels::Union(Nothing, Vector{String})
    ytick_labels::Union(Nothing, Vector{String})
    size::Union(Nothing, Vector{Measure})
    color::Union(Nothing, Vector{Color})

    function Aesthetics()
        new(nothing, nothing, nothing, nothing,
            nothing,nothing, nothing, nothing)
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


function update!(a::Aesthetics, b::Aesthetics)
    for name in Aesthetics.names
        if issomething(getfield(b, name))
            setfield(a, name, getfield(b, name))
        end
    end
end


function json(a::Aesthetics)
    join([strcat(a, ":", json(getfield(a, var))) for var in aes_vars], ",\n")
end


# Concatenate aesthetics.
#
# Args:
#   aess: One or more aesthetics.
#
# Returns:
#   A new Aesthetics instance with vectors concatenated.
#
function cat(aess::Aesthetics...)
    cataes = Aesthetics()

    for aes in aess
        for var in Aesthetics.names
            if getfield(aes, var) === nothing
                continue
            end

            if getfield(cataes, var) === nothing
                setfield(cataes, var, copy(getfield(aes, var)))
            else
                # This is a problem for not-Vector aesthetics
                append!(getfield(cataes, var), getfield(aes, var))
            end
        end
    end
    cataes
end
