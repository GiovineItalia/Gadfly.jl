

typealias NumericalOrCategoricalAesthetic
    Union(Nothing, Vector, DataArray, PooledDataArray)

typealias CategoricalAesthetic
    Union(Nothing, PooledDataArray)

typealias NumericalAesthetic
    Union(Nothing, Vector, DataArray)


@varset Aesthetics begin
    x,            NumericalOrCategoricalAesthetic
    y,            NumericalOrCategoricalAesthetic
    size,         Maybe(Vector{Measure})
    color,        Maybe(AbstractDataVector{ColorValue})
    label,        CategoricalAesthetic
    group,        CategoricalAesthetic

    xmin,         NumericalAesthetic
    xmax,         NumericalAesthetic
    ymin,         NumericalAesthetic
    ymax,         NumericalAesthetic

    # hexagon sizes used for hexbin
    xsize,        NumericalAesthetic
    ysize,        NumericalAesthetic

    # function plotting
    func,         NumericalOrCategoricalAesthetic

    # fixed lines
    xintercept,   NumericalAesthetic
    yintercept,   NumericalAesthetic

    # boxplots
    middle,       NumericalAesthetic
    lower_hinge,  NumericalAesthetic
    upper_hinge,  NumericalAesthetic
    lower_fence,  NumericalAesthetic
    upper_fence,  NumericalAesthetic
    outliers,     NumericalAesthetic

    # subplots
    xgroup,       CategoricalAesthetic
    ygroup,       CategoricalAesthetic

    # guides
    xtick,        NumericalAesthetic
    ytick,        NumericalAesthetic
    xgrid,        NumericalAesthetic
    ygrid,        NumericalAesthetic
    color_key_colors,     Maybe(Dict)
    color_key_title,      Maybe(String)
    color_key_continuous, Maybe(Bool)
    color_function,       Maybe(Function)
    titles,               Maybe(Dict{Symbol, String})

    # mark some ticks as initially invisible
    xtickvisible,         Maybe(Vector{Bool})
    ytickvisible,         Maybe(Vector{Bool})

    # scale at which ticks should become visible
    xtickscale,           Maybe(Vector{Float64})
    ytickscale,           Maybe(Vector{Float64})

    # pesudo-aesthetics used to indicate that drawing might
    # occur beyond any x/y value.
    xdrawmin,     Any
    xdrawmax,     Any
    ydrawmin,     Any
    ydrawmax,     Any

    # plot viewport extents
    xviewmin,     Any
    xviewmax,     Any
    yviewmin,     Any
    yviewmax,     Any

    # labeling functions
    x_label,      Function, default_formatter
    y_label,      Function, default_formatter
    xtick_label,  Function, default_formatter
    ytick_label,  Function, default_formatter
    color_label,  Function, default_formatter
    xgroup_label, Function, default_formatter
    ygroup_label, Function, default_formatter
end


# Alternate aesthetic names
const aesthetic_aliases =
    [:colour        => :color,
     :x_min         => :xmin,
     :x_max         => :xmax,
     :y_min         => :ymin,
     :y_max         => :ymax,
     :x_group       => :xgroup,
     :y_group       => :ygroup,
     :x_viewmin     => :xviewmin,
     :x_viewmax     => :xviewmax,
     :y_viewmin     => :yviewmin,
     :y_viewmax     => :yviewmax,
     :x_group_label => :xgroup_label,
     :y_group_label => :ygroup_label,
     :x_tick        => :xtick,
     :y_tick        => :ytick,
     :x_grid        => :xgrid,
     :y_grid        => :ygrid]


# Index as if this were a data frame
function getindex(aes::Aesthetics, i::Integer, j::String)
    getfield(aes, symbol(j))[i]
end


# Return the set of variables that are non-nothing.
function defined_aesthetics(aes::Aesthetics)
    vars = Set{Symbol}()
    for name in Aesthetics.names
        if !is(getfield(aes, name), nothing)
            push!(vars, name)
        end
    end
    vars
end


# Checking aesthetics and giving reasonable error messages.


# Raise an error if any of the given aesthetics are not defined.
#
# Args:
#   who: A string naming the caller which is printed in the error message.
#   aes: An Aesthetics object.
#   vars: Symbol that must be defined in the aesthetics.
#
function undefined_aesthetics(aes::Aesthetics, vars::Symbol...)
    setdiff(set(vars), defined_aesthetics(aes))
end

function assert_aesthetics_defined(who::String, aes::Aesthetics, vars::Symbol...)
    undefined_vars = undefined_aesthetics(aes, vars...)
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
            setfield!(cataes, var,
                      cat_aes_var!(getfield(cataes, var), getfield(aes, var)))
        end
    end
    cataes
end


cat_aes_var!(a::Nothing, b::Nothing) = a
cat_aes_var!(a::Nothing, b) = copy(b)
cat_aes_var!(a, b::Nothing) = a
cat_aes_var!(a::Function, b::Function) = a === string || a == default_formatter ? b : a


function cat_aes_var!(a::Dict, b::Dict)
    merge!(a, b)
    a
end



# work arround 0.2 weirdness
function cat_aes_var!(a::DataArray, b::AbstractArray)
    T = promote_type(eltype(a), eltype(b))
    da = DataArray(T, length(a) + length(b))
    copy!(da, [a..., b...])
    return da
end

function cat_aes_var!(a::AbstractArray, b::AbstractArray)
    return append!(a, b)
end


function cat_aes_var!(a, b)
    a
end


function cat_aes_var!{T}(xs::PooledDataVector{T}, ys::PooledDataVector{T})
    newpool = T[x for x in union(set(xs.pool), set(ys.pool))]
    newdata = vcat(T[x for x in xs], T[y for y in ys])
    PooledDataArray(newdata, newpool, [false for _ in newdata])
end


# Summarizing aesthetics

# Produce a matrix of Aesthetic objects partitioning the ariginal
# Aesthetics object by the cartesian product of xgroup and ygroup.
#
# This is useful primarily for drawing facets and subplots.
#
# Args:
#   aes: Aesthetics objects to partition.
#
# Returns:
#   A Array{Aesthetics} of size max(1, length(xgroup)) by
#   max(1, length(ygroup))
#
function aes_by_xy_group(aes::Aesthetics)
    @assert !is(aes.xgroup, nothing) || !is(aes.ygroup, nothing)
    @assert aes.xgroup === nothing || aes.ygroup === nothing ||
            length(aes.xgroup) == length(aes.ygroup)

    n = aes.ygroup === nothing ? 1 : maximum(aes.ygroup)
    m = aes.xgroup === nothing ? 1 : maximum(aes.xgroup)

    xrefs = aes.xgroup === nothing ? [1] : aes.xgroup
    yrefs = aes.ygroup === nothing ? [1] : aes.ygroup

    aes_grid = Array(Aesthetics, n, m)
    staging = Array(DataArray, n, m)
    for i in 1:n, j in 1:m
        aes_grid[i, j] = Aesthetics()
    end

    function make_pooled_data_array{T, U, V}(::Type{PooledDataArray{T,U,V}},
                                          arr::AbstractArray)
        PooledDataArray(convert(Array{T}, arr))
    end

    for var in Aesthetics.names

        # Skipped aesthetics. Don't try to partition aesthetics for which it
        # makes no sense to pass on to subplots.
        if var == :xgroup || var == :ygroup||
           var == :xtick || var == :ytick ||
           var == :xgrid || var == :ygrid ||
           var == :x_drawmin || var == :y_drawmin ||
           var == :x_drawmax || var == :y_drawmax ||
           var == :x_viewmin || var == :y_viewmin ||
           var == :x_viewmax || var == :y_viewmax ||
           var == :color_key_colors
            continue
        end

        vals = getfield(aes, var)
        if typeof(vals) <: AbstractArray
            if !is(aes.xgroup, nothing) && length(vals) != length(aes.xgroup) ||
               !is(aes.ygroup, nothing) && length(vals) != length(aes.ygroup)
                error("Aesthetic $(var) must be the same length as xgroup or ygroup")
            end

            for i in 1:n, j in 1:m
                staging[i, j] = DataArray(eltype(vals), 0)
            end

            for (i, j, v) in zip(Iterators.cycle(yrefs), Iterators.cycle(xrefs), vals)
                push!(staging[i, j], v)
            end

            for i in 1:n, j in 1:m
                if typeof(vals) <: PooledDataArray
                    setfield!(aes_grid[i, j], var,
                              make_pooled_data_array(typeof(vals), staging[i, j]))
                else
                    if !applicable(convert, typeof(vals), staging[i, j])
                        T = eltype(vals)
                        if T <: ColorValue T = ColorValue end
                        da = DataArray(T, length(staging[i, j]))
                        copy!(da, staging[i, j])
                        setfield!(aes_grid[i, j], var, da)
                    else
                        setfield!(aes_grid[i, j], var,
                                  convert(typeof(vals), copy(staging[i, j])))
                    end
                end
            end
        else
            for i in 1:n, j in 1:m
                setfield!(aes_grid[i, j], var, vals)
            end
        end
    end

    aes_grid
end


