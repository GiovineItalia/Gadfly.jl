
# Aesthetics is a set of bindings of typed values to symbols (Wilkinson calls
# this a Varset). Each variable controls how geometries are realized.
type Aesthetics
    x::Union(Nothing, Vector{Float64}, Vector{Int64})
    y::Union(Nothing, Vector{Float64}, Vector{Int64})
    size::Maybe(Vector{Measure})
    color::Maybe(AbstractDataVector{ColorValue})
    label::Maybe(PooledDataVector{UTF8String})

    x_min::Union(Nothing, Vector{Float64}, Vector{Int64})
    x_max::Union(Nothing, Vector{Float64}, Vector{Int64})
    y_min::Union(Nothing, Vector{Float64}, Vector{Int64})
    y_max::Union(Nothing, Vector{Float64}, Vector{Int64})

    # Boxplot aesthetics
    middle::Maybe(Vector{Float64})
    lower_hinge::Maybe(Vector{Float64})
    upper_hinge::Maybe(Vector{Float64})
    lower_fence::Maybe(Vector{Float64})
    upper_fence::Maybe(Vector{Float64})
    outliers::Maybe(Vector{Vector{Float64}})

    # Aesthetics pertaining to guides
    xtick::Maybe(Vector{Float64})
    ytick::Maybe(Vector{Float64})
    xgrid::Maybe(Vector{Float64})
    ygrid::Maybe(Vector{Float64})

    color_key_colors::Maybe(Vector{ColorValue})
    color_key_title::Maybe(String)
    color_key_continuous::Maybe(Bool)

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
            nothing, nothing, nothing, nothing,
            nothing, nothing, nothing, nothing,
            nothing, nothing, nothing, nothing,
            nothing, nothing, nothing, nothing,
            nothing, nothing,
            fmt_float, fmt_float,
            string, string, string)
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


# Index as if this were a data frame
function getindex(aes::Aesthetics, i::Integer, j::String)
    getfield(aes, symbol(j))[i]
end


# Serialization to JSON for the Compose D3 backend.
function write_data_frame(img::D3, aes::Aesthetics)
    println("WRITING AESTHETICS")
    usednames = Symbol[]
    for name in Aesthetics.names
        if typeof(getfield(aes, name)) <: AbstractArray
            push!(usednames, name)
        end
    end

    if isempty(usednames)
        return "[]"
    end

    n = length(getfield(aes, usednames[1]))
    m = length(usednames)

    write(img.out, "  [")
    for i in 1:n
        if i > 1
            write(img.out, "   ")
        end
        write(img.out, "{")
        for j in 1:m
            println((i, usednames[j]))
            @printf(img.out, "\"%s\": %s",
                    usednames[j],
                    to_json(getfield(aes, usednames[j])[i]))
            if j < m
                write(img.out, ", ")
            end
        end
        write(img.out, "}")
        if i < n
            write(img.out, ",\n")
        end
    end
    write(img.out, "]")
end


# Return the set of variables that are non-nothing.
function defined_aesthetics(aes::Aesthetics)
    vars = Set{Symbol}()
    for name in Aesthetics.names
        if !is(getfield(aes, name), nothing)
            add!(vars, name)
        end
    end
    vars
end


# Checking aesthetics and giving reasonable error messages.


# Raise an error if any of thu given aesthetics are not defined.
#
# Args:
#   who: A string naming the caller which is printed in the error message.
#   aes: An Aesthetics object.
#   vars: Symbol that must be defined in the aesthetics.
#
function assert_aesthetics_defined(who::String, aes::Aesthetics, vars::Symbol...)
    undefined_vars = setdiff(Set(vars...), defined_aesthetics(aes))
    if !isempty(undefined_vars)
        error(@sprintf("The following aesthetics are required by %s but are not defined: %s\n",
                       who, join(undefined_vars, ", ")))
    end
end


function assert_aesthetics_equal_length(who::String, aes::Aesthetics, vars::Symbol...)
    defined_vars = Symbol[]
    for var in filter(var -> !(getfield(aes, var) === nothing), vars)
        push!(defined_vars, var)
    end

    n = length(getfield(aes, vars[1]))
    for i in 2:length(vars)
        if length(getfield(aes, vars[1])) != n
            error(@sprintf("The following aesthetics are required by %s to be of equal length: %s\n",
                           who, join(vars, ", ")))
        end
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

# Args:
#  a: aesthetics to serialize.
#
# Returns:
#   JSON data as a string.
#
function json(a::Aesthetics)
    join([string(a, ":", json(getfield(a, var))) for var in aes_vars], ",\n")
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


