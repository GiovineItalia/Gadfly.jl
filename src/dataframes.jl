using .DataFrames

function meltdata(U::AbstractDataFrame, colgroups::Vector{Col.GroupedColumn})
    um, un = size(U)

    # Figure out the size of the new melted matrix
    allcolumns = Set{Symbol}(names(U))

    vm = um
    colidxs = [colgroup.columns===nothing ? collect(allcolumns) : colgroup.columns for colgroup in colgroups]
    vm *=  prod(length.(colidxs))
    grouped_columns = reduce(vcat, colidxs)

    ungrouped_columns = setdiff(allcolumns, grouped_columns)
    vn = length(colgroups) + length(ungrouped_columns)

    V = AbstractArray[]
    vnames = Symbol[]
    colmap = Dict{Any, Int}()

    eltypd = Dict(k=>v for (k,v) in zip(names(U), eltypes(U)))
    # allocate vectors for grouped columns
    for (j, (colgroup, colidx)) in enumerate(zip(colgroups, colidxs))
        eltyp = promote_type(getindex.([eltypd], colidx)...)
        push!(V, eltyp == Vector ? Array{eltyp}(undef, vm) : Array{Union{Nothing,eltyp}}(undef, vm))
        name = gensym()
        push!(vnames, name)
        colmap[colgroup] = j
    end

    # allocate vectors for ungrouped columns
    for (j, col) in enumerate(ungrouped_columns)
        push!(V, Array{eltypd[col]}(undef, vm))
        colmap[col] = j + length(colgroups)
        push!(vnames, col)
    end

    # Indicator columns for each colgroup
    col_indicators = Array{Symbol}(undef, vm, length(colgroups))
    row_indicators = Array{Int}(undef, vm, length(colgroups))

    vi = 1
    for ui in 1:um
        for colidx in Iterators.product(colidxs...)
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

evalmapping(source::MeltedData{T}, arg::Col.GroupedColumnValue) where T<:AbstractDataFrame =
    source.melted_data[:,source.colmap[Col.GroupedColumn(arg.columns)]]

evalmapping(source::AbstractDataFrame, arg::Symbol) = source[:,arg]
evalmapping(source::AbstractDataFrame, arg::AbstractString) = evalmapping(source, Symbol(arg))
evalmapping(source::AbstractDataFrame, arg::Integer) = source[:,arg]
evalmapping(source::AbstractDataFrame, arg::Expr) = with(source, arg)
