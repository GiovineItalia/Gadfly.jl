module Col

using Compat
using DataFrames
import IterTools
import Base: ==

struct GroupedColumn
    columns::Nullable{Vector}
end

Base.hash(colgroup::GroupedColumn, h::UInt64) = hash(colgroup.columns, h)

function ==(a::GroupedColumn, b::GroupedColumn)
    return (isnull(a.columns) && isnull(b.columns)) ||
        (!isnull(a.columns) && !isnull(b.columns) && get(a.columns) == get(b.columns))
end

Base.show(io::IO, gc::GroupedColumn) = print(io, "Column")

index() = GroupedColumn(Nullable{Vector}())

index(xs::T...) where {T <: (Union{Int, Symbol})} = GroupedColumn(Nullable(collect(T, xs)))

struct GroupedColumnValue
    columns::Nullable{Vector}
end

Base.show(io::IO, gc::GroupedColumnValue) = print(io, "Column Value")

value() = GroupedColumnValue(Nullable{Vector}())

value(xs::T...) where {T <: (Union{Int, Symbol})} = GroupedColumnValue(Nullable(collect(T, xs)))

end # module Col


module Row

using Compat

# represent a row index correspondig to a set of columns
struct GroupedColumnRowIndex
    columns::Nullable{Vector}
end

index() = GroupedColumnRowIndex(Nullable{Vector}())

index(xs::T...) where {T <: (Union{Int, Symbol})} = GroupedColumnRowIndex(Nullable(collect(T, xs)))

end # module Row


# Handle aesthetics aliases and warn about unrecognized aesthetics.
#
# Returns:
#   A new mapping with aliases evaluated and unrecognized aesthetics removed.
#
function cleanmapping(mapping::Dict)
    cleaned = Dict{Symbol, Any}()
    for (key, val) in mapping
        # skip the "order" pesudo-aesthetic, used to order layers
        key == :order && continue

        if haskey(aesthetic_aliases, key)
            key = aesthetic_aliases[key]
        elseif !in(key, fieldnames(Aesthetics))
            warn("$(string(key)) is not a recognized aesthetic. Ignoring.")
            continue
        end

        if val == Col.value || val == Col.index || val == Row.index
            val = val()
        end

        cleaned[key] = val
    end
    cleaned
end


# Type to contain fields produced by melting data (and to dispatch on)
struct MeltedData
    data
    melted_data
    row_indicators::Array
    col_indicators::Array
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

        push!(V, eltyp == Vector ? Array{eltyp}(vm) : DataArray(eltyp, vm))
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
    col_indicators = Array{Symbol}(vm, length(colgroups))
    row_indicators = Array{Int}(vm, length(colgroups))

    colidxs = [isnull(colgroup.columns) ? collect(allcolumns) : get(colgroup.columns)
               for colgroup in colgroups]

    vi = 1
    for ui in 1:um
        for colidx in IterTools.product(colidxs...)
            # copy grouped columns
            for (vj, uj) in enumerate(colidx)
                V[vj][vi] = U[ui, uj]
                col_indicators[vi, vj] = uj
                row_indicators[vi, vj] = ui
            end

            # copy ungrouped columns
            for (vj, uj) in enumerate(ungrouped_columns)
                V[vj + length(colgroups)][vi] = U[ui, uj]
            end

            vi += 1
        end
    end

    df = DataFrame(; collect(zip(vnames, V))...)
    return MeltedData(U, df, row_indicators, col_indicators, colmap)
end


function meltdata(U::AbstractVector, colgroups_::Vector{Col.GroupedColumn})
    colgroups = Set(colgroups_)

    if length(colgroups) != 1 || !isnull(first(colgroups).columns)
        # if every column is of the same length, treat it as a matrix
        if length(Set([length(u for u in U)])) == 1
            return meltdata(cat(2, U...), colgroups_)
        end

        # otherwise it doesn't make much sense
        error("Col.index/Col.value can only be used without arguments when plotting an array of heterogenous arrays")
    end
    colgroup = first(colgroups)
    colmap = Dict{Any, Int}()
    colmap[colgroup] = 1

    V = cat(1, U...)
    col_indicators = Array{Int}(length(V))
    row_indicators = Array{Int}(length(V))
    k = 1
    for i in 1:length(U)
        for j in 1:length(U[i])
            col_indicators[k] = i
            row_indicators[k] = j
            k += 1
        end
    end

    return MeltedData(U, V, row_indicators, col_indicators, colmap)
end


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
    col_indicators = Array{Int}((vm, length(colgroups)))
    row_indicators = Array{Int}((vm, length(colgroups)))

    colidxs = [isnull(colgroup.columns) ? collect(allcolumns) : get(colgroup.columns)
               for colgroup in colgroups]

    vi = 1
    for ui in 1:um, colidx in IterTools.product(colidxs...)
        # copy grouped columns
        for (vj, uj) in enumerate(colidx)
            V[vi, vj] = U[ui, uj]
            col_indicators[vi, vj] = uj
            row_indicators[vi, vj] = ui
        end

        # copy ungrouped columns
        for (vj, uj) in enumerate(ungrouped_columns)
            V[vi, vj + length(colgroups)] = U[ui, uj]
        end

        vi += 1
    end

    # Map grouped and individual columns in U to columns in V
    colmap = Dict{Any, Int}()
    for (vj, colgroup) in enumerate(colgroups)
        colmap[colgroup] = vj
    end
    for (vj, uj) in enumerate(ungrouped_columns)
        colmap[uj] = vj + length(colgroups)
    end

    return MeltedData(U, V, row_indicators, col_indicators, colmap)
end


# Evaluate one mapping.
evalmapping(source, arg::AbstractArray) = arg
evalmapping(source, arg::Function) = arg
evalmapping(source, arg::Distribution) = arg

evalmapping(source::AbstractDataFrame, arg::Symbol) = source[arg]
evalmapping(source::AbstractDataFrame, arg::AbstractString) = evalmapping(source, Symbol(arg))
evalmapping(source::AbstractDataFrame, arg::Integer) = source[arg]
evalmapping(source::AbstractDataFrame, arg::Expr) = with(source, arg)

evalmapping(source::MeltedData, arg::Integer) = source.melted_data[:,source.colmap[arg]]
evalmapping(source::MeltedData, arg::Col.GroupedColumn) = source.col_indicators[:,source.colmap[arg]]
evalmapping(source::MeltedData, arg::Col.GroupedColumnValue) =
    source.melted_data[:,source.colmap[Col.GroupedColumn(arg.columns)]]
evalmapping(source::MeltedData, arg::Row.GroupedColumnRowIndex) =
    source.row_indicators[:,source.colmap[Col.GroupedColumn(arg.columns)]]
evalmapping(source::MeltedData, arg::Symbol) =
    source.melted_data[:,source.colmap[arg]]
evalmapping(source::MeltedData, arg::AbstractString) =
    source.melted_data[:,source.colmap[Symbol(arg)]]
evalmapping(source::MeltedData, arg::Colon) = source.melted_data


# Evalute aesthetic mappings producting a Data instance.
function evalmapping!(mapping::Dict, data_source, data::Data)
    # Are we doing implicit reshaping?
    colgroups = Col.GroupedColumn[]
    for (k, v) in mapping
        if isa(v, Col.GroupedColumn)
            push!(colgroups, v)
        elseif isa(v, Col.GroupedColumnValue) || isa(v, Row.GroupedColumnRowIndex)
            push!(colgroups, Col.GroupedColumn(v.columns))
        end
    end

    if !isempty(colgroups) && !isa(data_source, MeltedData)
        data_source = meltdata(data_source, colgroups)
    end

    for (k, v) in mapping
        setfield!(data, k, evalmapping(data_source, v))
        data.titles[k] = isa(v, AbstractString) || isa(v, Symbol) ?  string(v) : string(k)
    end

    return data_source
end
