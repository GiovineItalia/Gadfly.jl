

using Measures

# 1 function to be moved to Measures.jl
Base.convert(::Type{T} , x::Measure) where T<:Real  = T(x.value)


struct DiscreteSizeScale <: Gadfly.ScaleElement
    f::Function
    levels::Union{Nothing, AbstractVector}
    order::Union{Nothing, AbstractVector}
    preserve_order::Bool
end 
DiscreteSizeScale(f; levels=nothing, order=nothing, preserve_order=true) =
        DiscreteSizeScale(f, levels, order, preserve_order)

element_aesthetics(scale::DiscreteSizeScale) = [:size]

default_discrete_sizes(n::Int) = range(0.45mm, 1.8mm, length=n)

"""
    size_discrete2(f=default_discrete_sizes; 
                    levels=nothing, order=nothing, preserve_order=true)

A discrete size scale that maps the categorical values in the `size`
aesthetic to x-axis units or `Measure` units (from Measures.jl).  `f` is a function that produces a vector of size units.
`levels` are the categorical levels, and level order will be respected.  `order` is
a vector of integers giving a permutation of the levels default order.  If
`preserve_order` is `true` levels are ordered as they appear in the data.
"""
size_discrete2(f::Function=Gadfly.current_theme().discrete_sizemap; levels=nothing, order=nothing, preserve_order=true) =
        DiscreteSizeScale(f, levels, order, preserve_order)


function Scale.apply_scale(scale::DiscreteSizeScale, aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)

    d = []
    for (aes, data) in zip(aess, datas)
        data.size === nothing && continue
        append!(d, skipmissing(data.size))
    end
    levelset = unique(d)

    if scale.levels == nothing
        scale_levels = [levelset...]
        scale.preserve_order || sort!(scale_levels)
    else
        scale_levels = scale.levels
    end
    scale.order == nothing || permute!(scale_levels, scale.order)

    sizes = scale.f(length(scale_levels))

    size_map = Dict(s=>string(label) for (s, label) in zip(sizes, scale_levels))
    labeler(xs) = [size_map[x] for x in xs]
    key_vals = OrderedDict(s=>i for (i,s) in enumerate(sizes))

    for (aes, data) in zip(aess, datas)
        data.size === nothing && continue
        ds = discretize([d for d in skipmissing(data.size)], scale_levels)
        vals = sizes[ds.index]
        aes.size = discretize_make_ia(vals, sizes)
        aes.size_label = labeler
        aes.size_key_vals = key_vals
    end
end


