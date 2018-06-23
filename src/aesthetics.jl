const NumericalOrCategoricalAesthetic =
    Union{(Void), Vector, DataArray, IndirectArray}

const CategoricalAesthetic =
    Union{(Void), IndirectArray}

const NumericalAesthetic =
    Union{(Void), Matrix, Vector, DataArray}


@varset Aesthetics begin
    x,            Union{NumericalOrCategoricalAesthetic, Distribution}
    y,            Union{NumericalOrCategoricalAesthetic, Distribution}
    z,            Union{(Void), Function, NumericalAesthetic}
    xend,         NumericalAesthetic
    yend,         NumericalAesthetic

    size,         Union{CategoricalAesthetic,Vector,Void}
    shape,        Union{CategoricalAesthetic,Vector,Void}
    color,        Union{CategoricalAesthetic,Vector,Void}

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
    intercept,    NumericalAesthetic
    slope,        NumericalAesthetic

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
    Dict{Symbol, Symbol}(:colour        => :color,
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
getindex(aes::Aesthetics, i::Integer, j::AbstractString) = getfield(aes, Symbol(j))[i]


# Return the set of variables that are non-nothing.
function defined_aesthetics(aes::Aesthetics)
    vars = Set{Symbol}()
    for name in fieldnames(Aesthetics)
        getfield(aes, name) === nothing || push!(vars, name)
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
undefined_aesthetics(aes::Aesthetics, vars::Symbol...) =
        setdiff(Set(vars), defined_aesthetics(aes))

function assert_aesthetics_defined(who::AbstractString, aes::Aesthetics, vars::Symbol...)
    undefined_vars = undefined_aesthetics(aes, vars...)
    isempty(undefined_vars) || error("The following aesthetics are required by ",who,
            " but are not defined: ", join(undefined_vars,", "),"\n")
end

function assert_aesthetics_undefined(who::AbstractString, aes::Aesthetics, vars::Symbol...)
    defined_vars = intersect(Set(vars), defined_aesthetics(aes))
    isempty(defined_vars) || error("The following aesthetics are defined but incompatible with ",
            who,": ",join(defined_vars,", "),"\n")
end

function assert_aesthetics_equal_length(who::AbstractString, aes::Aesthetics, vars::Symbol...)
    defined_vars = Compat.Iterators.filter(var -> !(getfield(aes, var) === nothing), vars)

    if !isempty(defined_vars)
        n = length(getfield(aes, first(defined_vars)))
        for var in defined_vars
            length(getfield(aes, var)) != n && error(
                    "The following aesthetics are required by ",who,
                    " to be of equal length: ",join(defined_vars,", "),"\n")
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
        issomething(getfield(b, name)) && setfield(a, name, getfield(b, name))
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
json(a::Aesthetics) = join([string(a, ":", json(getfield(a, var))) for var in aes_vars], ",\n")


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


cat_aes_var!(a::(Void), b::(Void)) = a
cat_aes_var!(a::(Void), b::Union{Function,AbstractString}) = b
cat_aes_var!(a::(Void), b) = copy(b)
cat_aes_var!(a, b::(Void)) = a
cat_aes_var!(a::Function, b::Function) = a === string || a == showoff ? b : a

function cat_aes_var!(a::Dict, b::Dict)
    merge!(a, b)
    a
end

cat_aes_var!(a::AbstractArray{T}, b::AbstractArray{T}) where {T <: Base.Callable} = append!(a, b)
cat_aes_var!(a::AbstractArray{T}, b::AbstractArray{U}) where {T <: Base.Callable, U <: Base.Callable} =
        a=[promote(a..., b...)...]

# Let arrays of numbers clobber arrays of functions. This is slightly odd
# behavior, comes up with with function statistics applied on a layer-wise
# basis.
cat_aes_var!(a::AbstractArray{T}, b::AbstractArray{U}) where {T <: Base.Callable, U} = b
cat_aes_var!(a::AbstractArray{T}, b::AbstractArray{U}) where {T, U <: Base.Callable} = a
cat_aes_var!(a::AbstractArray{T}, b::AbstractArray{T}) where {T} = append!(a, b)
cat_aes_var!(a, b) = a

function cat_aes_var!(a::AbstractArray{T}, b::AbstractArray{U}) where {T, U}
    V = promote_type(T, U)
    if isa(a, DataArray) || isa(b, DataArray)
        ab = DataArray(V, length(a) + length(b))
    else
        ab = Array{V}(length(a) + length(b))
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

function cat_aes_var!(xs::IndirectArray{T,1}, ys::IndirectArray{S,1}) where {T, S}
    TS = promote_type(T, S)
    return append!(IndirectArray(xs.index, convert(Array{TS},xs.values)),
                   IndirectArray(ys.index, convert(Array{TS},ys.values)))
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
function by_xy_group(aes::T, xgroup, ygroup,
                     num_xgroups, num_ygroups) where T <: Union{Data, Aesthetics}
    @assert xgroup === nothing || ygroup === nothing || length(xgroup) == length(ygroup)

    n = num_ygroups
    m = num_xgroups

    xrefs = xgroup === nothing ? [1] : xgroup
    yrefs = ygroup === nothing ? [1] : ygroup

    aes_grid = Array{T}(n, m)
    staging = Array{AbstractArray}(n, m)
    for i in 1:n, j in 1:m
        aes_grid[i, j] = T()
    end

    xgroup === nothing && ygroup === nothing && return aes_grid

    function make_pooled_array(::Type{IndirectArray{T,N,A,V}}, arr::AbstractArray) where {T,N,A,V}
        uarr = unique(arr)
        return IndirectArray(A(indexin(arr, uarr)), V(uarr))
    end
    make_pooled_array(::Type{IndirectArray{T,R,N,RA}},
            arr::IndirectArray{T,R,N,RA}) where {T,R,N,RA} = arr

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
            if xgroup !== nothing && length(vals) !== length(xgroup) ||
               ygroup !== nothing && length(vals) !== length(ygroup)
                continue
            end

            for i in 1:n, j in 1:m
                staging[i, j] = similar(vals, 0)
            end

            for (i, j, v) in zip(Compat.Iterators.cycle(yrefs), Compat.Iterators.cycle(xrefs), vals)
                push!(staging[i, j], v)
            end

            for i in 1:n, j in 1:m
                if typeof(vals) <: IndirectArray
                    setfield!(aes_grid[i, j], var,
                              make_pooled_array(typeof(vals), staging[i, j]))
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
            bval != nothing && (aval == nothing || aval > bval) && setfield!(a, field, bval)
        elseif field == :xviewmax || field == :yviewmax
            bval != nothing && (aval == nothing || aval < bval) && setfield!(a, field, bval)
        elseif typeof(aval) <: Dict && typeof(bval) <: Dict
            merge!(aval, getfield(b, field))
        end
    end
    nothing
end

"""
    groupby(aes, by, togroupvar)

Given aesthetics to group with, `by`, and an aesthetic to group `togroupvar`
this function constructs a dictionary that maps each given combination of the
`by` aesthetics to the positions which they apply to. Thus the output is a
dictionary of tuples of each unique combination of `by` mapped to a boolean
array of length `n` where `n` is the length of the aesthetics (they have to all
have the same length). If the provided aesthetics are missing, a placeholder
`nothing` is return instead of the unique value.

## Examples

```jldoctest
using Gadfly
aes = Gadfly.Aesthetics()
aes.x = repeat([1, 2], inner=3)
aes.y = collect(1:6)

Gadfly.groupby(aes, [:x, :color], :y)

# output

DataStructures.OrderedDict{Tuple{Int64,Void},Array{Bool,1}} with 2 entries:
  (1, nothing) => Bool[true, true, true, false, false, false]
  (2, nothing) => Bool[false, false, false, true, true, true]
```

```jldoctest
using Gadfly
aes = Gadfly.Aesthetics()
aes.x = repeat([:a, :b], inner=2)
aes.y = collect(1:4)
aes.color = repeat([colorant"red", colorant"blue"], inner=2)

Gadfly.groupby(aes, [:x, :color], :y)

# output

DataStructures.OrderedDict{Tuple{Symbol,ColorTypes.RGB{FixedPointNumbers.Normed{UInt8,8}}},Array{Bool,1}} with 2 entries:
  (:a, RGB{N0f8}(1.0,0.0,0.0)) => Bool[true, true, false, false]
  (:b, RGB{N0f8}(0.0,0.0,1.0)) => Bool[false, false, true, true]
```

"""
function groupby(aes::Gadfly.Aesthetics, by::Vector{Symbol}, togroupvar::Symbol)
    types = fill(Nothing, length(by))
    isconcrete = fill(false, length(by))
    for i in 1:length(by)
        isconcrete[i] = getfield(aes, by[i]) != nothing
        (!isconcrete[i]) && continue
        types[i] = eltype(getfield(aes, by[i]))
        @assert length(getfield(aes, togroupvar)) == length(getfield(aes, by[i])) "$togroupvar and $(by[i]) aesthetics must have same length"
    end

    grouped = DataStructures.OrderedDict{Tuple{types...}, Vector{Bool}}()

    # gather options for each `by` aesthetic
    opt = [if isconcrete[i] unique(getfield(aes, by[i])) else [nothing] end for i in 1:length(by)]

    # The approach is to identify positions were multiple by aesthetics overlap
    # and thus grouping the data positions. We first assume that all positions
    # belong to a combination of aesthetics and then whittle it down
    for combo in IterTools.product(opt...)
        belongs = fill(true, length(getfield(aes, togroupvar)))
        for i in 1:length(combo)
            (combo[i] == nothing) && continue
            belongs .&= getfield(aes, by[i]) .== combo[i]
        end
        # for multiple by variables we need to check whether there is any overlap
        # between this specific combo before adding it to the dict
        (any(belongs)) && (grouped[combo] = belongs)
    end
    grouped
end
