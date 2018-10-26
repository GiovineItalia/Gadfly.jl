using .DataFrames

function meltdata(U::AbstractDataFrame, colgroups_::Vector{Col.GroupedColumn})
    um, un = size(U)

    colgroups = Set(colgroups_)

    # Figure out the size of the new melted matrix
    allcolumns = Set{Symbol}(names(U))

    vm = um
    grouped_columns = Set{Symbol}()
    for colgroup in colgroups
        if colgroup.columns===nothing # null => group all columns
            vm *= un
            grouped_columns = copy(allcolumns)
        else
            for j in colgroup.columns
                if !isa(j, Symbol)
                    error("DataFrame columns can only be grouped by (Symbol) names")
                end
                push!(grouped_columns, j)
            end
            vm *= length(colgroup.columns)
        end
    end

    ungrouped_columns = setdiff(allcolumns, grouped_columns)
    vn = length(colgroups) + length(ungrouped_columns)

    V = AbstractArray[]
    vnames = Symbol[]
    colmap = Dict{Any, Int}()

    # allocate vectors for grouped columns
    for (j, colgroup) in enumerate(colgroups)
        cols = colgroup.columns===nothing ? allcolumns : colgroup.columns

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

        push!(V, eltyp == Vector ? Array{eltyp}(undef, vm) : Array{Union{Nothing,eltyp}}(undef, vm))
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
    col_indicators = Array{Symbol}(undef, vm, length(colgroups))
    row_indicators = Array{Int}(undef, vm, length(colgroups))

    colidxs = [colgroup.columns===nothing ? collect(allcolumns) : colgroup.columns
               for colgroup in colgroups]

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
    source.melted_data[source.colmap[Col.GroupedColumn(arg.columns)]]

evalmapping(source::AbstractDataFrame, arg::Symbol) = source[arg]
evalmapping(source::AbstractDataFrame, arg::AbstractString) = evalmapping(source, Symbol(arg))
evalmapping(source::AbstractDataFrame, arg::Integer) = source[arg]
evalmapping(source::AbstractDataFrame, arg::Expr) = with(source, arg)
