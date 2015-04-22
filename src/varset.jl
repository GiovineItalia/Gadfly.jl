

# Generate large types where each field has a default value to which it's
# initialized.

macro varset(name::Symbol, table)
    @assert table.head == :block
    table = table.args

    names = Any[]
    vars = Any[]
    defaults = Any[]
    parameters = Any[]
    parameters_expr = Expr(:parameters)

    for row in table
        if typeof(row) == Expr && row.head == :line
            continue
        end

        if typeof(row) == Symbol
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
        push!(defaults, default)
        push!(parameters, Expr(:kw, var, default))
        parameters_expr = Expr(:parameters, parameters...)
    end

    new_with_defaults = Expr(:call, :new, names...)

    ex =
    quote
        type $(name)
            $(vars...)

            function $(name)()
                new($(defaults...))
            end

            function $(name)($(parameters_expr))
                $(new_with_defaults)
            end

            # shallow copy constructor
            function $(name)(a::$(name))
                b = new()
                for name in fieldnames($(name))
                    setfield!(b, name, getfield(a, name))
                end
                b
            end
        end

        function copy(a::$(name))
            $(name)(a)
        end
    end

    esc(ex)
end


