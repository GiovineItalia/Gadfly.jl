# Generate large types where each field has an optional default value
# to which it's initialized.  the format of each row in `table` is
# "[doc str], variable name, [variable type, [default value, [depwarn
# str]]]", where square brackets indicate optional elements.

macro varset(name::Symbol, table)
    @assert table.head == :block
    table = table.args

    names = Any[]
    vars = Any[]
    depwarns = Any[]
    parsed_vars = Any[]
    parameters = Any[]
    parameters_expr = Expr(:parameters)
    inherit_parameters = Any[]
    inherit_parameters_expr = Expr(:parameters)

    for row in table
        isa(row, LineNumberNode) && continue

        hasdocstr = false
        if isa(row, Symbol)
            var = row
            typ = :Any
            default = :nothing
            depwarnstr = ""
        elseif row.head == :tuple && 2 <= length(row.args) <= 5
            if isa(row.args[1], String)
                docstr = row.args[1]
                hasdocstr = true
            end
            var = row.args[hasdocstr+1]
            typ = row.args[hasdocstr+2]
            default = length(row.args)-hasdocstr > 2 ? row.args[hasdocstr+3] : :nothing
            depwarnstr = length(row.args)-hasdocstr > 3 ? row.args[hasdocstr+4] : ""
        else
            error("Bad varset syntax ", row)
        end

        push!(names, var)
        hasdocstr && push!(vars, :($docstr))
        isempty(depwarnstr) || push!(depwarns, :($var != $default && Base.depwarn($depwarnstr, Symbol($name))))
        push!(vars, :($(var)::$(typ)))
        push!(parameters, Expr(:kw, var, default))
        push!(inherit_parameters, Expr(:kw, var, :(b.$var)))
        if typ==:ColorOrNothing
            push!(parsed_vars, :($(var)==nothing ? nothing : parse_colorant($(var))))
        else
            push!(parsed_vars, :($(var)))
        end
    end

    parameters_expr = Expr(:parameters, parameters...)
    inherit_parameters_expr = Expr(:parameters, inherit_parameters...)

    ex =
    quote
        Base.@__doc__ mutable struct $(name)
            $(vars...)
        end

        function $(name)($(parameters_expr))
            $(depwarns...)
            return $(name)($(parsed_vars...))
        end
        $(name)($(inherit_parameters_expr), b::$name) = $(name)($(names...))
        copy(a::$(name)) = $(name)(a)
    end

    esc(ex)
end
