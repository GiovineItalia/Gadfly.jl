module Col

using Compat
using DataFrames
import Iterators
import Base: ==

immutable GroupedColumn
    columns::Nullable{Vector}
end


function Base.hash(colgroup::GroupedColumn, h::UInt64)
    return hash(colgroup.columns, h)
end


function ==(a::GroupedColumn, b::GroupedColumn)
    return (isnull(a.columns) && isnull(b.columns)) ||
        (!isnull(a.columns) && !isnull(b.columns) && get(a.columns) == get(b.columns))
end


function Base.show(io::IO, gc::GroupedColumn)
    print(io, "Column")
end


function index()
    return GroupedColumn(Nullable{Vector}())
end


function index{T <: (@compat Union{Int, Symbol})}(xs::T...)
    return GroupedColumn(Nullable(collect(T, xs)))
end


immutable GroupedColumnValue
    columns::Nullable{Vector}
end


function Base.show(io::IO, gc::GroupedColumnValue)
    print(io, "Column Value")
end


function value()
    return GroupedColumnValue(Nullable{Vector}())
end


function value{T <: (@compat Union{Int, Symbol})}(xs::T...)
    return GroupedColumnValue(Nullable(collect(T, xs)))
end


end # module Col


# Handle aesthetics aliases and warn about unrecognized aesthetics.
#
# Returns:
#   A new mapping with aliases evaluated and unrecognized aesthetics removed.
#
function cleanmapping(mapping::Dict)
    cleaned = Dict{Symbol, Any}()
    for (key, val) in mapping
        # skip the "order" pesudo-aesthetic, used to order layers
        if key == :order
            continue
        end

        if haskey(aesthetic_aliases, key)
            key = aesthetic_aliases[key]
        elseif !in(key, fieldnames(Aesthetics))
            warn("$(string(key)) is not a recognized aesthetic. Ignoring.")
            continue
        end

        if val == Col.value || val == Col.index
            val = val()
        end

        cleaned[key] = val
    end
    cleaned
end


# Type to contain fields produced by melting data (and to dispatch on)
immutable MeltedData
    data
    melted_data
    indicators::Array
    colmap::Dict
end


function meltdata(U::AbstractDataFrame, colgroups_::Vector{Col.GroupedColumn})
    um, un = size(U)

    colgroups = Set(colgroups_)

    # Figure out the size of the new melted matrix
    allcolumns = Set{Symbol}(names(U))

    vm = um
    grouped_columns = Set{Symbol}()
    for colgroup in colgroups
        if isnull(colgroup.columns) # null => group all columns
            vm *= un
            grouped_columns = copy(allcolumns)
        else
            for j in get(colgroup.columns)
                if !isa(j, Symbol)
                    error("DataFrame columns can only be grouped by (Symbol) names")
                end
                push!(grouped_columns, j)
            end
            vm *= length(get(colgroup.columns))
        end
    end

    ungrouped_columns = setdiff(allcolumns, grouped_columns)
    vn = length(colgroups) + length(ungrouped_columns)

    V = AbstractArray[]
    vnames = Symbol[]
    colmap = Dict{Any, Int}()

    # allocate vectors for grouped columns
    for (j, colgroup) in enumerate(colgroups)
        cols = isnull(colgroup.columns) ? allcolumns : get(colgroup.columns)

        # figure the grouped common column type
        firstcol = U[first(cols)]
        eltyp = eltype(firstcol)
        vectyp = isa(firstcol, Vector) ? Vector : DataVector
        for col in cols
            eltyp = promote_type(eltyp, typeof(U[col]))
            if !isa(U[col], Vector)
                vectyp = DataVector
            end
        end

        push!(V, eltyp == Vector ? Array(eltyp, vm) : DataArray(eltyp, vm))
        name = gensym()
        push!(vnames, name)
        colmap[colgroup] = j
    end

    # allocate vectors for ungrouped columns
    for (j, col) in enumerate(ungrouped_columns)
        push!(V, similar(U[col], vm))
        colmap[col] = j + length(colgroups)
        push!(vnames, col)
    end

    # Indicator columns for each colgroup
    indicators = Array(Symbol, (vm, length(colgroups)))

    colidxs = [isnull(colgroup.columns) ? collect(allcolumns) : get(colgroup.columns)
               for colgroup in colgroups]

    vi = 1
    for ui in 1:um
        for colidx in Iterators.product(colidxs...)
            # copy grouped columns
            for (vj, uj) in enumerate(colidx)
                V[vj][vi] = U[ui, uj]
                indicators[vi, vj] = uj
            end

            # copy ungrouped columns
            for (vj, uj) in enumerate(ungrouped_columns)
                V[vj + length(colgroups)][vi] = U[ui, uj]
            end

            vi += 1
        end
    end

    df = DataFrame(; collect(zip(vnames, V))...)
    return MeltedData(U, df, indicators, colmap)
end


# TODO: The is too elaborate. All matrix melts should const of all column, and
# we should reserve this elaborate melting logic for data frames.
function meltdata(U::AbstractMatrix, colgroups_::Vector{Col.GroupedColumn})
    um, un = size(U)

    colgroups = Set(colgroups_)

    # Figure out the size of the new melted matrix
    allcolumns = IntSet()
    for i in 1:un
        push!(allcolumns, i)
    end

    vm = um
    grouped_columns = IntSet()
    for colgroup in colgroups
        if isnull(colgroup.columns)
            vm *= un
            grouped_columns = copy(allcolumns)
        else
            for j in get(colgroup.columns)
                push!(grouped_columns, j)
            end
            vm *= length(get(colgroup.columns))
        end
    end

    ungrouped_columns = setdiff(allcolumns, grouped_columns)
    vn = length(colgroups) + length(ungrouped_columns)
    V = similar(U, (vm, vn))

    # Indicator columns for each colgroup
    indicators = Array(Int, (vm, length(colgroups)))

    colidxs = [isnull(colgroup.columns) ? collect(allcolumns) : get(colgroup.columns)
               for colgroup in colgroups]

    vi = 1
    for ui in 1:um
        for colidx in Iterators.product(colidxs...)
            # copy grouped columns
            for (vj, uj) in enumerate(colidx)
                V[vi, vj] = U[ui, uj]
                indicators[vi, vj] = uj
            end

            # copy ungrouped columns
            for (vj, uj) in enumerate(ungrouped_columns)
                V[vi, vj + length(colgroups)] = U[ui, uj]
            end

            vi += 1
        end
    end

    # Map grouped and individual columns in U to columns in V
    colmap = Dict{Any, Int}()
    for (vj, colgroup) in enumerate(colgroups)
        colmap[colgroup] = vj
    end
    for (vj, uj) in enumerate(ungrouped_columns)
        colmap[uj] = vj + length(colgroups)
    end

    return MeltedData(U, V, indicators, colmap)
end


# Evaluate one mapping.
evalmapping(source, arg::AbstractArray) = arg
evalmapping(source, arg::Function) = arg
evalmapping(source, arg::Distribution) = arg

evalmapping(source::AbstractDataFrame, arg::Symbol) = source[arg]
evalmapping(source::AbstractDataFrame, arg::AbstractString) = evalmapping(source, Symbol(arg))
evalmapping(source::AbstractDataFrame, arg::Integer) = source[arg]
evalmapping(source::AbstractDataFrame, arg::Expr) = with(source, arg)


function evalmapping(source::MeltedData, arg::Integer)
    return source.melted_data[:,source.colmap[arg]]
end


function evalmapping(source::MeltedData, arg::Col.GroupedColumn)
    return source.indicators[:,source.colmap[arg]]
end


function evalmapping(source::MeltedData, arg::Col.GroupedColumnValue)
    return source.melted_data[:,source.colmap[Col.GroupedColumn(arg.columns)]]
end


function evalmapping(source::MeltedData, arg::Colon)
    return source.melted_data
end


# Evalute aesthetic mappings producting a Data instance.
function evalmapping!(mapping::Dict, data_source, data::Data)
    # Are we doing implicit reshaping?
    colgroups = Col.GroupedColumn[]
    for (k, v) in mapping
        if isa(v, Col.GroupedColumn)
            push!(colgroups, v)
        elseif isa(v, Col.GroupedColumnValue)
            push!(colgroups, Col.GroupedColumn(v.columns))
        end
    end

    if !isempty(colgroups)
        data_source = meltdata(data_source, colgroups)
    end

    for (k, v) in mapping
        setfield!(data, k, evalmapping(data_source, v))
        data.titles[k] = isa(v, AbstractString) || isa(v, Symbol) ?  string(v) : string(k)
    end

    return data_source
end

