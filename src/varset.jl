

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
            error("Bad varset systax")
        end

        push!(names, var)
        push!(vars, :($(var)::$(typ)))
        push!(parameters, Expr(:kw, var, default))
        push!(inherit_parameters, Expr(:kw, var, :(b.$var)))
        parameters_expr = Expr(:parameters, parameters...)
        inherit_parameters_expr = Expr(:parameters, inherit_parameters...)
    end

    new_with_defaults = Expr(:call, :new, names...)

    ex =
    quote
        type $(name)
            $(vars...)

            function $(name)($(parameters_expr))
                $(new_with_defaults)
            end

            function $(name)($(inherit_parameters_expr), b::$name)
                $(new_with_defaults)
            end
        end

        function copy(a::$(name))
            $(name)(a)
        end
    end

    esc(ex)
end
