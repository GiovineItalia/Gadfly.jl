

typealias NumericalOrCategoricalAesthetic
    @compat(Union{(@compat Void), Vector, DataArray, PooledDataArray})

typealias CategoricalAesthetic
    @compat(Union{(@compat Void), PooledDataArray})

typealias NumericalAesthetic
    @compat(Union{(@compat Void), Matrix, Vector, DataArray})


@varset Aesthetics begin
    x,            @compat(Union{NumericalOrCategoricalAesthetic, Distribution})
    y,            @compat(Union{NumericalOrCategoricalAesthetic, Distribution})
    z,            @compat(Union{(@compat Void), Function, Matrix})
    xend,         NumericalAesthetic
    yend,         NumericalAesthetic
    size,         Maybe(Vector{Measure})
    shape,        CategoricalAesthetic
    color,        Maybe(@compat(Union{AbstractVector{RGBA{Float32}},
                              AbstractVector{RGB{Float32}}}))
    label,        CategoricalAesthetic
    group,        CategoricalAesthetic

    xmin,         NumericalAesthetic
    xmax,         NumericalAesthetic
    ymin,         NumericalAesthetic
    ymax,         NumericalAesthetic

    # hexagon sizes used for hexbin
    xsize,        NumericalAesthetic
    ysize,        NumericalAesthetic

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
    width,        NumericalAesthetic

    # subplots
    xgroup,       CategoricalAesthetic
    ygroup,       CategoricalAesthetic

    # guides
    xtick,        NumericalAesthetic
    ytick,        NumericalAesthetic
    xgrid,        NumericalAesthetic
    ygrid,        NumericalAesthetic
    color_key_colors,     Maybe(Associative)
    color_key_title,      Maybe(AbstractString)
    color_key_continuous, Maybe(Bool)
    color_function,       Maybe(Function)
    titles,               Maybe(Dict{Symbol, AbstractString})

    # mark some ticks as initially invisible
    xtickvisible,         Maybe(Vector{Bool})
    ytickvisible,         Maybe(Vector{Bool})

    # scale at which ticks should become visible
    xtickscale,           Maybe(Vector{Float64})
    ytickscale,           Maybe(Vector{Float64})

    # plot viewport extents
    xviewmin,     Any
    xviewmax,     Any
    yviewmin,     Any
    yviewmax,     Any

    # labeling functions
    x_label,      Function, showoff
    y_label,      Function, showoff
    xtick_label,  Function, showoff
    ytick_label,  Function, showoff
    color_label,  Function, showoff
    xgroup_label, Function, showoff
    ygroup_label, Function, showoff

    # pseudo-aesthetics
    pad_categorical_x, Nullable{Bool}, Nullable{Bool}()
    pad_categorical_y, Nullable{Bool}, Nullable{Bool}()
end


function show(io::IO, data::Aesthetics)
    maxlen = 0
    print(io, "Aesthetics(")
    for name in fieldnames(Aesthetics)
        if getfield(data, name) != nothing
            print(io, "\n  ", string(name), "=")
            show(io, getfield(data, name))
        end
    end
    print(io, "\n)\n")
end


# Alternate aesthetic names
const aesthetic_aliases =
    @compat Dict{Symbol, Symbol}(:colour        => :color,
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
                                 :y_grid        => :ygrid)


# Index as if this were a data frame
function getindex(aes::Aesthetics, i::Integer, j::AbstractString)
    getfield(aes, Symbol(j))[i]
end


# Return the set of variables that are non-nothing.
function defined_aesthetics(aes::Aesthetics)
    vars = Set{Symbol}()
    for name in fieldnames(Aesthetics)
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
    setdiff(Set(vars), defined_aesthetics(aes))
end


function assert_aesthetics_defined(who::AbstractString, aes::Aesthetics, vars::Symbol...)
    undefined_vars = undefined_aesthetics(aes, vars...)
    if !isempty(undefined_vars)
        error(@sprintf("The following aesthetics are required by %s but are not defined: %s\n",
                       who, join(undefined_vars, ", ")))
    end
end


function assert_aesthetics_undefined(who::AbstractString, aes::Aesthetics, vars::Symbol...)
    defined_vars = intersect(Set(vars), defined_aesthetics(aes))
    if !isempty(defined_vars)
        error(@sprintf("The following aesthetics are defined but incompatible with %s: %s\n",
                       who, join(undefined_vars, ", ")))
    end
end


function assert_aesthetics_equal_length(who::AbstractString, aes::Aesthetics, vars::Symbol...)
    defined_vars = filter(var -> !(getfield(aes, var) === nothing), vars)

    if !isempty(defined_vars)
        n = length(getfield(aes, first(defined_vars)))
        for var in defined_vars
            if length(getfield(aes, var)) != n
                error(@sprintf("The following aesthetics are required by %s to be of equal length: %s\n",
                               who, join(defined_vars, ", ")))
            end
        end
    end
    nothing
end


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
    for name in fieldnames(Aesthetics)
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
function concat(aess::Aesthetics...)
    cataes = Aesthetics()
    for aes in aess
        for var in fieldnames(Aesthetics)
            if var in [:xviewmin, :yviewmin]
                mu, mv = getfield(cataes, var), getfield(aes, var)
                setfield!(cataes, var,
                          mu === nothing ? mv :
                             mv == nothing ? mu :
                                 min(mu, mv))
            elseif var in [:xviewmax, :yviewmax]
                mu, mv = getfield(cataes, var), getfield(aes, var)
                setfield!(cataes, var,
                          mu === nothing ? mv :
                             mv == nothing ? mu :
                                 max(mu, mv))
            else
                setfield!(cataes, var,
                          cat_aes_var!(getfield(cataes, var), getfield(aes, var)))
            end
        end
    end
    cataes
end


cat_aes_var!(a::(@compat Void), b::(@compat Void)) = a
cat_aes_var!(a::(@compat Void), b::Union{Function,AbstractString}) = b
cat_aes_var!(a::(@compat Void), b) = copy(b)
cat_aes_var!(a, b::(@compat Void)) = a
cat_aes_var!(a::Function, b::Function) = a === string || a == showoff ? b : a


function cat_aes_var!(a::Dict, b::Dict)
    merge!(a, b)
    a
end


function cat_aes_var!{T <: Base.Callable}(a::AbstractArray{T}, b::AbstractArray{T})
    return append!(a, b)
end


function cat_aes_var!{T <: Base.Callable, U <: Base.Callable}(a::AbstractArray{T}, b::AbstractArray{U})
    return append!(a, b)
end


# Let arrays of numbers clobber arrays of functions. This is slightly odd
# behavior, comes up with with function statistics applied on a layer-wise
# basis.
function cat_aes_var!{T <: Base.Callable, U}(a::AbstractArray{T}, b::AbstractArray{U})
    return b
end


function cat_aes_var!{T, U <: Base.Callable}(a::AbstractArray{T}, b::AbstractArray{U})
    return a
end


function cat_aes_var!{T}(a::AbstractArray{T}, b::AbstractArray{T})
    return append!(a, b)
end


function cat_aes_var!{T, U}(a::AbstractArray{T}, b::AbstractArray{U})
    V = promote_type(T, U)
    if isa(a, DataArray) || isa(b, DataArray)
        ab = DataArray(V, length(a) + length(b))
    else
        ab = Array(V, length(a) + length(b))
    end
    i = 1
    for x in a
        ab[i] = x
        i += 1
    end
    for x in b
        ab[i] = x
        i += 1
    end

    return ab
end


function cat_aes_var!(a, b)
    a
end


function cat_aes_var!{T}(xs::PooledDataVector{T}, ys::PooledDataVector{T})
    newpool = T[x for x in union(Set(xs.pool), Set(ys.pool))]
    newdata = vcat(T[x for x in xs], T[y for y in ys])
    PooledDataArray(newdata, newpool, [false for _ in newdata])
end


function cat_aes_var!{T, U}(xs::PooledDataVector{T}, ys::PooledDataVector{U})
    V = promote_type(T, U)
    newpool = V[x for x in union(Set(xs.pool), Set(ys.pool))]
    newdata = vcat(V[x for x in xs], V[y for y in ys])
    PooledDataArray(newdata, newpool, [false for _ in newdata])
end


# Summarizing aesthetics

# Produce a matrix of Aesthetic or Data objects partitioning the original
# Aesthetics or Data object by the cartesian product of xgroup and ygroup.
#
# This is useful primarily for drawing facets and subplots.
#
# Args:
#   aes: Aesthetics or Data objects to partition.
#
# Returns:
#   A Array{Aesthetics} of size max(1, length(xgroup)) by
#   max(1, length(ygroup))
#
function by_xy_group{T <: @compat(Union{Data, Aesthetics})}(aes::T, xgroup, ygroup,
                                                   num_xgroups, num_ygroups)
    @assert xgroup === nothing || ygroup === nothing ||
            length(xgroup) == length(ygroup)

    n = num_ygroups
    m = num_xgroups

    xrefs = xgroup === nothing ? [1] : xgroup
    yrefs = ygroup === nothing ? [1] : ygroup

    aes_grid = Array(T, n, m)
    staging = Array(AbstractArray, n, m)
    for i in 1:n, j in 1:m
        aes_grid[i, j] = T()
    end

    if is(xgroup, nothing) && is(ygroup, nothing)
        return aes_grid
    end

    function make_pooled_data_array{T, U, V}(::Type{PooledDataArray{T,U,V}},
                                             arr::AbstractArray)
        PooledDataArray(convert(Array{T}, arr))
    end
    make_pooled_data_array{T, U, V}(::Type{PooledDataArray{T,U,V}},
                                    arr::PooledDataArray{T, U, V}) = arr

    for var in fieldnames(T)
        # Skipped aesthetics. Don't try to partition aesthetics for which it
        # makes no sense to pass on to subplots.
        if var == :xgroup || var == :ygroup||
           var == :xtick || var == :ytick ||
           var == :xgrid || var == :ygrid ||
           var == :x_viewmin || var == :y_viewmin ||
           var == :x_viewmax || var == :y_viewmax ||
           var == :color_key_colors
            continue
        end

        vals = getfield(aes, var)
        if typeof(vals) <: AbstractArray
            if !is(xgroup, nothing) && length(vals) != length(xgroup) ||
               !is(ygroup, nothing) && length(vals) != length(ygroup)
                error("Aesthetic $(var) must be the same length as xgroup or ygroup")
            end

            for i in 1:n, j in 1:m
                staging[i, j] = similar(vals, 0)
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
                        T2 = eltype(vals)
                        if T2 <: Color T2 = Color end
                        da = DataArray(T2, length(staging[i, j]))
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

function inherit(a::Aesthetics, b::Aesthetics;
                 clobber=[])
    acopy = copy(a)
    inherit!(acopy, b, clobber=clobber)
    return acopy
end

function inherit!(a::Aesthetics, b::Aesthetics;
                  clobber=[])
    clobber_set = Set{Symbol}(clobber)
    for field in fieldnames(Aesthetics)
        aval = getfield(a, field)
        bval = getfield(b, field)
        if field in clobber_set
            setfield!(a, field, bval)
        elseif aval === nothing || aval === string || aval == showoff
            setfield!(a, field, bval)
        elseif field == :xviewmin || field == :yviewmin
            if bval != nothing && (aval == nothing || aval > bval)
                setfield!(a, field, bval)
            end
        elseif field == :xviewmax || field == :yviewmax
            if bval != nothing && (aval == nothing || aval < bval)
                setfield!(a, field, bval)
            end
        elseif typeof(aval) <: Dict && typeof(bval) <: Dict
            merge!(aval, getfield(b, field))
        end
    end
    nothing
end
