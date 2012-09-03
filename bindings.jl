
# Aesthetic bindings, which work much like variable scoping.

type NilBindings end
const nil_bindings = NilBindings()

type Bindings
    parent::Union(Bindings, NilBindings)
    vars::Dict{Symbol, Any}

    function Bindings()
        new(nil_bindings, Dict{Symbol, Any}())
    end
end


function get(bindings::Bindings, sym::Symbol)
    if has(bindings.vars, sym)
        bindings.vars[sym]
    else
        get(bindings.parent, sym)
    end
end


function get(bindings::NilBindings, sym::Symbol)
    error(@sprintf("Aesthetic %s must be defined.", string(sym)))
end

