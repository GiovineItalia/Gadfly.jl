# Generate large types where each field has a default value to which it's
# initialized.

macro varset(name::Symbol, table)
    @assert table.head == :block
    table = table.args

    names = Any[]
    vars = Any[]
    parameters = Any[]
    parameters_expr = Expr(:parameters)
    inherit_parameters = Any[]
    inherit_parameters_expr = Expr(:parameters)

    for row in table
        if isa(row, Expr) && row.head == :line
            continue
        end

        if isa(row, Symbol)
            var = row
            typ = :Any
            default = :nothing
        elseif row.head == :tuple
            @assert 2 <= length(row.args) <= 3
            var = row.args[1]
            typ = row.args[2]
            default = length(row.args) > 2 ? row.args[3] : :nothing
        else
            error("Bad varset syntax")
        end

        push!(names, var)
        push!(vars, :($(var)::$(typ)))
        push!(parameters, Expr(:kw, var, default))
        push!(inherit_parameters, Expr(:kw, var, :(b.$var)))
    end

    parameters_expr = Expr(:parameters, parameters...)
    inherit_parameters_expr = Expr(:parameters, inherit_parameters...)

    ex =
    quote
        type $(name)
            $(vars...)
        end

        $(name)($(parameters_expr)) = $(name)($(names...))
        $(name)($(inherit_parameters_expr), b::$name) = $(name)($(names...))
        copy(a::$(name)) = $(name)(a)
    end

    esc(ex)
end
