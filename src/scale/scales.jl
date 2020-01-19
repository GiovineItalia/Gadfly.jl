

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



area_transform = ContinuousScaleTransform(a->sqrt(a/π), r->π*r*r, identity_formatter)

struct ContinuousSizeScale <: Gadfly.ScaleElement
    # A function of the form f(p) where 0 ≤ p ≤ 1, that returns a Measure.
    f::Function
    trans::ContinuousScaleTransform
    minvalue::Maybe(Compose.MeasureOrNumber)
    maxvalue::Maybe(Compose.MeasureOrNumber)
    format::Union{Nothing, Symbol}
end

Scale.element_aesthetics(scale::ContinuousSizeScale) = [:size]

default_continuous_sizes(p::Float64; min=0mm, max=2mm) = min + p*(max-min)


"""
    Scale.size_radius(f=default_continuous_sizes; minvalue=0.0, maxvalue=nothing)

A scale for continuous sizes. Values in the `size` aesthetic are mapped either to: 
- x-axis units (if `maxvalue=nothing`), or
-  `Measure` units (from Measures.jl). 
If `maxvalue` is specified, the continuous sizes are converted to a proportion
(between `minvalue` and `maxvalue`), and then mapped to absolute sizes using the function `f(p)` where `0≤p≤1`.
"""
size_radius(f::Function=Gadfly.current_theme().continuous_sizemap; minvalue=0.0, maxvalue=nothing) =
     ContinuousSizeScale(f, identity_transform, minvalue, maxvalue, nothing)



"""
    Scale.size_area(f=default_continuous_sizes; minvalue=0.0, maxvalue=nothing)

Similar to [`Scale.size_radius`](@ref), except that the values in the `size` aesthetic are
scaled to area rather than radius, before mapping to x-axis units or `Measure` units.    
"""
function size_area(f::Function=Gadfly.current_theme().continuous_sizemap; minvalue=0.0, maxvalue=nothing)
    (isa(minvalue, Measure) || isa(maxvalue, Measure)) &&
        throw(ArgumentError("Scale.size_area maps the size variable to absolute size via the function `f`. See `?Scale.size_radius` for more info."))
     return ContinuousSizeScale(f, area_transform, minvalue, maxvalue, nothing)
end



function apply_scale(scale::ContinuousSizeScale, aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)

    sdata = reduce(vcat, [d.size for d in datas if d.size≠nothing])

    showvals = length(sdata)>1
    dmax = maximum(skipmissing(sdata))
    
    strict_span = false
    (smin, smax) =
        if scale.maxvalue===nothing
            promote(scale.minvalue, dmax)
        else
            strict_span = true
            promote(scale.minvalue, scale.maxvalue)
        end
    ticks = Gadfly.optimize_ticks(smin, smax, strict_span=strict_span)[1]
    Δ = scale.trans.f(ticks[end])-scale.trans.f(ticks[1])
    labels = scale.trans.label(ticks)

# Transform ticks e.g. to areas/porportions/sizes
    keyvals = if scale.maxvalue===nothing
            showvals = false
            scale.trans.f.(ticks.-smin)
        else
            p = (scale.trans.f.(ticks) .- scale.trans.f(ticks[1]))./Δ
            scale.f.(p)
        end
    
    labeldict = Dict(k=>v for (k,v) in zip(keyvals, labels))
    key_vals= OrderedDict(s=>i for (i,s) in enumerate(keyvals))
    labeler(xs) = [labeldict[x] for x in xs]
    
    for (aes, data) in zip(aess, datas)
            data.size===nothing && continue

            ds = if scale.maxvalue === nothing
                    scale.trans.f.(data.size.-smin)
                else
                    p = (scale.trans.f.(data.size).-scale.trans.f(ticks[1]))./Δ
                    scale.f.(p)
                end
        aes.size = ds
        showvals && (aes.size_key_vals = key_vals)
        aes.size_label = labeler
    end
end




