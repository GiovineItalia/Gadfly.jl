
require("Compose.jl")
using Compose

# TODO: These should probably be DataVec{Float64} not Vector{Float64}

# Aesthetics is a set of bindings of typed values to symbols (Wilkinson calls
# this a Varset). Each variable controls how geometries are realized.
type Aesthetics
    # TODO: x and y in particular should be DataVec to allow for missing data
    x::Union(Nothing, Vector{Float64}, Vector{Int64})
    y::Union(Nothing, Vector{Float64}, Vector{Int64})
    size::Maybe(Vector{Measure})
    color::Maybe(PooledDataVec{Color})

    # Aesthetics pertaining to guides
    xtick::Maybe(Vector{Float64})
    ytick::Maybe(Vector{Float64})

    color_key_colors::Maybe(Vector{Color})

    # Labels. These are not aesthetics per se, but functions that assign lables
    # to values taken by aesthetics. Often this means simply inverting the
    # application of a scale to arrive at the original value.
    x_label::Function
    y_label::Function
    xtick_label::Function
    ytick_label::Function
    color_label::Function

    function Aesthetics()
        new(nothing, nothing, nothing, nothing,
            nothing, nothing, nothing, fmt_float,
            fmt_float, string, string, string)
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


# Create a shallow copy of an Aesthetics instance.
#
# Args:
#   a: aesthetics to copy
#
# Returns:
#   Copied aesthetics.
#
copy(a::Aesthetics) = Aesthetics(a)


# Replace values in a with non-nothing values in b.
#
# Args:
#   a: Destination.
#   b: Source.
#
# Returns: nothing
#
# Modifies: a
#
function update!(a::Aesthetics, b::Aesthetics)
    for name in Aesthetics.names
        if issomething(getfield(b, name))
            setfield(a, name, getfield(b, name))
        end
    end

    nothing
end


# Serialize aesthetics to JSON.
#
# Args:
#  a: aesthetics to serialize.
#
# Returns:
#   JSON data as a string.
#
function json(a::Aesthetics)
    join([strcat(a, ":", json(getfield(a, var))) for var in aes_vars], ",\n")
end


# Concatenate aesthetics.
#
# A new Aesthetics instance is produced with data vectors in each of the given
# Aesthetics concatenated, nothing being treated as an empty vector.
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
            setfield(cataes, var,
                     cat_aes_var!(getfield(cataes, var), getfield(aes, var)))
        end
    end
    cataes
end

cat_aes_var!(a::Nothing, b::Nothing) = a
cat_aes_var!(a::Nothing, b) = b
cat_aes_var!(a, b::Nothing) = a
cat_aes_var!(a::Function, b::Function) = a === string || a === fmt_float ? b : a
function cat_aes_var!(a, b)
    append!(a, b)
    a
end


