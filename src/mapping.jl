module Col

using Compat
import Base: ==

struct GroupedColumn
    columns::Union{Nothing,Vector}
end

Base.hash(colgroup::GroupedColumn, h::UInt64) = hash(colgroup.columns, h)

==(a::GroupedColumn, b::GroupedColumn) = a.columns==b.columns

Base.show(io::IO, gc::GroupedColumn) = print(io, "Column")

index() = GroupedColumn(nothing)

index(xs::T...) where {T <: (Union{Int, Symbol})} = GroupedColumn(collect(Union{Nothing,T}, xs))

struct GroupedColumnValue
    columns::Union{Nothing,Vector}
end

Base.show(io::IO, gc::GroupedColumnValue) = print(io, "Column Value")

value() = GroupedColumnValue(nothing)

value(xs::T...) where {T <: (Union{Int, Symbol})} = GroupedColumnValue(collect(Union{Nothing,T}, xs))

end # module Col


module Row

using Compat

# represent a row index correspondig to a set of columns
struct GroupedColumnRowIndex
    columns::Union{Nothing,Vector}
end

index() = GroupedColumnRowIndex(nothing)

index(xs::T...) where {T <: (Union{Int, Symbol})} = GroupedColumnRowIndex(collect(Union{Nothing,T}, xs))

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
            # redefining key could have performance impacts
            newkey = aesthetic_aliases[key]
        elseif in(key, valid_aesthetics)
            newkey = key
        else
            @warn "$(string(key)) is not a recognized aesthetic. Ignoring."
            continue
        end

        newval = val == Col.value || val == Col.index || val == Row.index ? val() : val

        cleaned[newkey] = newval
    end
    cleaned
end


# Type to contain fields produced by melting data (and to dispatch on)
struct MeltedData{T}
    data
    melted_data::T
    row_indicators::Array
    col_indicators::Array
    colmap::Dict
end

function meltdata(U::AbstractVector, colgroups_::Vector{Col.GroupedColumn})
    colgroups = Set(colgroups_)

    if length(colgroups) != 1 || first(colgroups).columns!==nothing
        # if every column is of the same length, treat it as a matrix
        if length(Set([length(u for u in U)])) == 1
            return meltdata(cat(U..., dims=2), colgroups_)
        end

        # otherwise it doesn't make much sense
        error("Col.index/Col.value can only be used without arguments when plotting an array of heterogenous arrays")
    end
    colgroup = first(colgroups)
    colmap = Dict{Any, Int}()
    colmap[colgroup] = 1

    V = cat(U..., dims=1)
    col_indicators = Array{Int}(undef, length(V))
    row_indicators = Array{Int}(undef, length(V))
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
    allcolumns = BitSet()
    for i in 1:un
        push!(allcolumns, i)
    end

    vm = um
    grouped_columns = BitSet()
    for colgroup in colgroups
        if colgroup.columns===nothing
            vm *= un
            grouped_columns = copy(allcolumns)
        else
            for j in colgroup.columns
                push!(grouped_columns, j)
            end
            vm *= length(colgroup.columns)
        end
    end

    ungrouped_columns = setdiff(allcolumns, grouped_columns)
    vn = length(colgroups) + length(ungrouped_columns)
    V = similar(U, (vm, vn))

    # Indicator columns for each colgroup
    col_indicators = Array{Int}(undef, vm, length(colgroups))
    row_indicators = Array{Int}(undef, vm, length(colgroups))

    colidxs = [colgroup.columns===nothing ? collect(allcolumns) : colgroup.columns
               for colgroup in colgroups]

    vi = 1
    for ui in 1:um, colidx in Iterators.product(colidxs...)
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


# Share common functionality between general and melted-data-specific methods
function _evalmapping!(mapping::Dict, data_source, data::Data)
    for (k, v) in mapping
        setfield!(data, k, evalmapping(data_source, v))
        data.titles[k] = isa(v, AbstractString) || isa(v, Symbol) ?  string(v) : string(k)
    end

    return data_source
end

# Evalute aesthetic mappings producting a Data instance.
evalmapping!(mapping::Dict, data_source::MeltedData, data::Data) =
    _evalmapping!(mapping, data_source, data)

# Need to do additional work only if data_source is not MeltedData
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

    transformed_data_source = if !isempty(colgroups)
        meltdata(data_source, colgroups)
    else
        data_source
    end

    return _evalmapping!(mapping, transformed_data_source, data)
end

function link_dataframes()
    @debug "Loading DataFrames support into Gadfly"
    include("dataframes.jl")
end
