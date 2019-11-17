module Scale

using Colors
using Compose
using DataStructures
using Gadfly
using Showoff
using IndirectArrays
using CategoricalArrays
using Printf
using Base.Iterators

import Gadfly: element_aesthetics, isconcrete, concrete_length, discretize_make_ia,
    aes2str, valid_aesthetics
import Distributions: Distribution

include("color_misc.jl")

iscategorical(scales::Dict{Symbol, Gadfly.ScaleElement}, var::Symbol) =
        haskey(scales, var) && isa(scales[var], DiscreteScale)

function apply_scales(scales, aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for scale in scales
        apply_scale(scale, aess, datas...)
    end

    for (aes, data) in zip(aess, datas)
        aes.titles = data.titles
    end
end

function apply_scales(scales, datas::Gadfly.Data...)
    aess = Gadfly.Aesthetics[Gadfly.Aesthetics() for _ in datas]
    apply_scales(scales, aess, datas...)
    aess
end


# Transformations on continuous scales
struct ContinuousScaleTransform
    f::Function     # transform function
    finv::Function  # f's inverse

    # A function taking one or more values and returning an array of
    # strings.
    label::Function
end

identity_formatter(xs::AbstractArray, format=:auto) = showoff(xs, format)
const identity_transform = ContinuousScaleTransform(identity, identity, identity_formatter)

log10_formatter(xs::AbstractArray, format=:plain) =
        [@sprintf("10<sup>%s</sup>", x) for x in showoff(xs, format)]
const log10_transform = ContinuousScaleTransform(log10, x -> 10^x, log10_formatter)

log2_formatter(xs::AbstractArray, format=:plain) =
        [@sprintf("2<sup>%s</sup>", x) for x in showoff(xs, format)]
const log2_transform = ContinuousScaleTransform(log2, x -> 2^x, log2_formatter)

log_formatter(xs::AbstractArray, format=:plain) =
        [@sprintf("e<sup>%s</sup>", x) for x in showoff(xs, format)]
const log_transform = ContinuousScaleTransform(log, exp, log_formatter)

asinh_formatter(xs::AbstractArray, format=:plain) =
        [@sprintf("sinh(%s)", x) for x in showoff(xs, format)]
const asinh_transform = ContinuousScaleTransform(asinh, sinh, asinh_formatter)

sqrt_formatter(xs::AbstractArray, format=:plain) =
        [@sprintf("%s<sup>2</sup>", x) for x in showoff(xs, format)]
const sqrt_transform = ContinuousScaleTransform(sqrt, x -> x^2, sqrt_formatter)


# Continuous scale maps data on a continuous scale simple by calling
# `convert(Float64, ...)`.
struct ContinuousScale <: Gadfly.ScaleElement
    vars::Vector{Symbol}
    trans::ContinuousScaleTransform
    minvalue
    maxvalue
    minticks
    maxticks
    labels::Union{(Nothing), Function}
    format
    scalable

    function ContinuousScale(vars, trans,
                             minvalue, maxvalue, minticks, maxticks,
                             labels, format, scalable)
        minvalue != nothing && maxvalue != nothing && minvalue > maxvalue &&
                error("Cannot construct a ContinuousScale with minvalue > maxvalue")
        new(vars, trans, minvalue, maxvalue, minticks, maxticks, labels, format, scalable)
    end
end

function ContinuousScale(vars, trans;
                         labels=nothing,
                         minvalue=nothing, maxvalue=nothing,
                         minticks=2, maxticks=10, format=nothing, scalable=true)
    ContinuousScale(vars, trans, minvalue, maxvalue, minticks, maxticks, labels, format, scalable)
end

function make_labeler(scale::ContinuousScale)
    if scale.labels != nothing
        xs -> [scale.labels(x) for x in xs]
    elseif scale.format == nothing
        scale.trans.label
    else
        xs -> scale.trans.label(xs, scale.format)
    end
end

const x_vars = [:x, :xmin, :xmax, :xintercept, :xviewmin, :xviewmax, :xend]
const y_vars = [:y, :ymin, :ymax, :yintercept, :intercept, :middle, :upper_fence, :lower_fence,
                :upper_hinge, :lower_hinge, :yviewmin, :yviewmax, :yend]

element_aesthetics(scale::ContinuousScale) = scale.vars

function continuous_scale_partial(vars::Vector{Symbol}, trans::ContinuousScaleTransform)
    function(; minvalue=nothing, maxvalue=nothing, labels=nothing, format=nothing,
             minticks=2, maxticks=10, scalable=true)
        ContinuousScale(vars, trans, minvalue=minvalue, maxvalue=maxvalue,
                        labels=labels, format=format, minticks=minticks,
                        maxticks=maxticks, scalable=scalable)
    end
end

xy_continuous_docstr(var, aess) = """
    $(var)_continuous[(; minvalue=nothing, maxvalue=nothing, labels=nothing,
                       format=nothing, minticks=2, maxticks=10, scalable=true)]

Map $(aess) to $var positions in Cartesian coordinates, which are presumed to
be numerical, using an identity transform.  `minvalue` and `maxvalue` set soft
lower and upper bounds.  (Use [`Coord.cartesian`](@ref) to enforce a hard
bound.)  `labels` is a function which maps a coordinate value to a string
label.  `format` is one of `:plain`, `:scientific`, `:engineering`, or `:auto`.
Set `scalable` to false to prevent zooming on this axis.  See also
[`$(var)_log10`](@ref), [`$(var)_log2`](@ref), [`$(var)_log`](@ref),
[`$(var)_asinh`](@ref), and [`$(var)_sqrt`](@ref) for alternatives to the
identity transform.
"""

# can be put on two lines with julia 0.7
@doc xy_continuous_docstr("x", aes2str(element_aesthetics(x_continuous()))) const x_continuous = continuous_scale_partial(x_vars, identity_transform)

@doc xy_continuous_docstr("y", aes2str(element_aesthetics(y_continuous()))) const y_continuous = continuous_scale_partial(y_vars, identity_transform)

xy_fun_docstr(var,fun) = """
    $(var)_$(fun)[(; minvalue=nothing, maxvalue=nothing, labels=nothing,
                       format=nothing, minticks=2, maxticks=10, scalable=true)]

Similar to [`Scale.$(var)_continuous`](@ref), except that the aesthetics are
`$(fun)` transformed and the `labels` function inputs transformed values.
"""

for xy in [:x,:y], fun in [:log10, :log2, :log, :asinh, :sqrt]
  @eval @doc $(xy_fun_docstr(xy,fun)) const $(Symbol(xy,'_',fun)) = continuous_scale_partial($(Symbol(xy,"_vars")), $(Symbol(fun,"_transform")))
end

"""
    size_continuous[(; minvalue=nothing, maxvalue=nothing, labels=nothing,
                     format=nothing, minticks=2, maxticks=10, scalable=true)]
"""
const size_continuous = continuous_scale_partial([:size], identity_transform)

"""
    slope_continuous[(; minvalue=nothing, maxvalue=nothing, labels=nothing,
                     format=nothing, minticks=2, maxticks=10, scalable=true)]
"""
const slope_continuous = continuous_scale_partial([:slope], identity_transform)

"""
    alpha_continuous[(; minvalue=0.0, maxvalue=1.0, labels=nothing,
                     format=nothing, minticks=2, maxticks=10, scalable=true)]

Rescale the data values between `minvalue` and `maxvalue` to opacity (alpha) values between 0 and 1.
"""
alpha_continuous(; minvalue=0.0, maxvalue=1.0, labels=nothing, format=nothing, minticks=2, maxticks=10, scalable=true) =
     ContinuousScale([:alpha], identity_transform, minvalue=minvalue, maxvalue=maxvalue,
               labels=labels, format=format, minticks=minticks, maxticks=maxticks, scalable=scalable)


function apply_scale(scale::ContinuousScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        for var in scale.vars
            vals = getfield(data, var)
            if vals isa CategoricalArray
                throw(ArgumentError("continuous scale for $var aesthetic when stored as a CategoricalArray. Consider using a discrete scale or convert data to an Array."))
            end
            vals === nothing && continue

            # special case for function arrays bound to :y
            # pass the function values through and wait for the scale to
            # be reapplied by Stat.func
            if var == :y && eltype(vals) <: Function
                aes.y = vals
                continue
            end

            # special case for Distribution values bound to :x or :y. wait for
            # scale to be re-applied by Stat.qq
            if in(var, [:x, :y]) && typeof(vals) <: Distribution
                setfield!(aes, var, vals)
                continue
            end

            T = Any
            for d in vals
                if isconcrete(d)
                    T = typeof(scale.trans.f(d))
                    break
                end
            end

            T <: Measure && (T = Measure)

            ds = any(ismissing, vals) ? Array{Union{Missing,T}}(undef,length(vals)) :
                    Array{T}(undef,length(vals))
            apply_scale_typed!(ds, vals, scale)

            if var == :alpha
                ds = (vals.-scale.minvalue)./(scale.maxvalue-scale.minvalue)
             end

            if var == :xviewmin || var == :xviewmax ||
               var == :yviewmin || var == :yviewmax
                setfield!(aes, var, ds[1])
            else
                setfield!(aes, var, ds)
            end

            if var in x_vars
                label_var = :x_label
            elseif var in y_vars
                label_var = :y_label
            else
                label_var = Symbol(var, "_label")
            end

            if in(label_var, valid_aesthetics)
                setfield!(aes, label_var, make_labeler(scale))
            end
        end

        if scale.minvalue != nothing
            if scale.vars === x_vars
                aes.xviewmin = scale.trans.f(scale.minvalue)
            elseif scale.vars === y_vars
                aes.yviewmin = scale.trans.f(scale.minvalue)
            end
        end

        if scale.maxvalue != nothing
            if scale.vars === x_vars
                aes.xviewmax = scale.trans.f(scale.maxvalue)
            elseif scale.vars === y_vars
                aes.yviewmax = scale.trans.f(scale.maxvalue)
            end
        end
    end
end

function apply_scale_typed!(ds, field, scale::ContinuousScale)
    for i in 1:length(field)
        d = field[i]
        ds[i] = isconcrete(d) ? scale.trans.f(d) : d
    end
end


function discretize(values, levels=nothing, order=nothing, preserve_order=true)
    if levels == nothing
        if preserve_order
            levels = OrderedSet()
            for value in values
                push!(levels, value)
            end
            da = discretize_make_ia(values, collect(eltype(values), levels))
        else
            da = discretize_make_ia(values)
        end
    else
        da = discretize_make_ia(values, levels)
    end

    if order != nothing
        return discretize_make_ia(da, da.values[order])
    else
        return da
    end
end

struct DiscreteScaleTransform
    f::Function
end

struct DiscreteScale <: Gadfly.ScaleElement
    vars::Vector{Symbol}
    labels::Union{(Nothing), Function}
    levels::Union{(Nothing), AbstractVector}
    order::Union{(Nothing), AbstractVector}
end
DiscreteScale(vals; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale(vals, labels, levels, order)

const discrete = DiscreteScale

element_aesthetics(scale::DiscreteScale) = scale.vars

xy_discrete_docstr(var, aess) = """
    $(var)_discrete[(; labels=nothing, levels=nothing, order=nothing)]

Map $(aess), which are presumed to be categorical, to Cartesian coordinates.
Unlike [`Scale.x_continuous`](@ref), each unique $var value will be mapped to
equally spaced positions, regardless of value.

By default continuous scales are applied to numerical data. If data consists of
numbers specifying categories, explicitly adding `Scale.$(var)_discrete` is the
easiest way to get that data to plot appropriately.

`labels` is either a function which maps a coordinate value to a string label,
or a vector of strings of the same length as the number of unique values in the
aesthetic.  `levels` gives values for the scale.  Order will be respected and
anything in the data that's not respresented in `levels` will be set to
`missing`.  `order` is a vector of integers giving a permutation of the levels
default order.

See also [`group_discrete`](@ref), [`shape_discrete`](@ref),
[`size_discrete`](@ref), [`linestyle_discrete`](@ref), and [`alpha_discrete`](@ref).
"""

@doc xy_discrete_docstr("x", aes2str(element_aesthetics(x_discrete()))) x_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale(x_vars, labels=labels, levels=levels, order=order)

@doc xy_discrete_docstr("y", aes2str(element_aesthetics(y_discrete()))) y_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale(y_vars, labels=labels, levels=levels, order=order)

type_discrete_docstr(aes) = """
    $(aes)_discrete[(; labels=nothing, levels=nothing, order=nothing)]

Similar to [`Scale.x_discrete`](@ref), except applied to the `$aes` aesthetic.
"""

@doc type_discrete_docstr("group") group_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:group], labels=labels, levels=levels, order=order)

@doc type_discrete_docstr("shape") shape_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:shape], labels=labels, levels=levels, order=order)

@doc type_discrete_docstr("size") size_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:size], labels=labels, levels=levels, order=order)

"""
    alpha_discrete[(; labels=nothing, levels=nothing, order=nothing)]

Similar to [`Scale.x_discrete`](@ref), except applied to the `alpha` aesthetic. The alpha palette
is set by `Theme(alphas=[])`.
"""
alpha_discrete(; labels=nothing, levels=nothing, order=nothing) =
            DiscreteScale([:alpha], labels=labels, levels=levels, order=order)

@doc type_discrete_docstr("linestyle") linestyle_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:linestyle], labels=labels, levels=levels, order=order)


function apply_scale(scale::DiscreteScale, aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        for var in scale.vars
            label_var = Symbol(var, "_label")
            getfield(data, var) === nothing && continue

            disc_data = discretize(getfield(data, var), scale.levels, scale.order)
            setfield!(aes, var, discretize_make_ia(Int64.(disc_data.index)))

            # The leveler for discrete scales is a closure over the discretized data.
            if scale.labels === nothing
                function default_labeler(xs)
                    lvls = filter(!ismissing, disc_data.values)
                    vals = Any[1 <= x <= length(lvls) ? lvls[x] : "" for x in xs]
                    if all([isa(val, AbstractFloat) for val in vals])
                        return showoff(vals)
                    else
                        return [string(val) for val in vals]
                    end
                end
                labeler = default_labeler
            else
                function explicit_labeler(xs)
                    lvls = filter(!ismissing, disc_data.values)
                    return [string(scale.labels(lvls[x])) for x in xs]
                end
                labeler = explicit_labeler
            end

            in(label_var, valid_aesthetics) && setfield!(aes, label_var, labeler)
        end
    end
end


struct NoneColorScale <: Gadfly.ScaleElement
end

"""
    color_none

Suppress the default color scale that some statistics impose by setting the
`color` aesthetic to `nothing`.
"""
const color_none = NoneColorScale

element_aesthetics(scale::NoneColorScale) = [:color]

function apply_scale(scale::NoneColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for aes in aess
        aes.color = nothing
    end
end


struct IdentityColorScale <: Gadfly.ScaleElement
end

"""
    color_identity
"""
const color_identity = IdentityColorScale

element_aesthetics(scale::IdentityColorScale) = [:color]

function apply_scale(scale::IdentityColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        data.color === nothing && continue
        aes.color = discretize_make_ia(data.color)
        aes.color_key_colors = Dict()
    end
end


struct DiscreteColorScale <: Gadfly.ScaleElement
    f::Function
    levels::Union{(Nothing), AbstractVector}
    order::Union{(Nothing), AbstractVector}
    preserve_order::Bool
end
DiscreteColorScale(f; levels=nothing, order=nothing, preserve_order=true) =
        DiscreteColorScale(f, levels, order, preserve_order)

element_aesthetics(scale::DiscreteColorScale) = [:color]

default_discrete_colors(n) = convert(Vector{Color},
        distinguishable_colors(n,
                               [LCHab(70, 60, 240)],
                               transform=c -> deuteranopic(c, 0.5),
                               lchoices=Float64[65, 70, 75, 80],
                               cchoices=Float64[0, 50, 60, 70],
                               hchoices=range(0, stop=330, length=24)))

"""
    color_discrete_hue[(f; levels=nothing, order=nothing, preserve_order=true)]

Create a discrete color scale that maps the categorical levels in the `color`
aesthetic to `Color`s.  `f` is a function that produces a vector of colors.
`levels` gives values for the scale.  Order will be respected and anything in
the data that's not represented in `levels` will be set to missing.  `order` is
a vector of integers giving a permutation of the levels default order.  If
`preserve_order` is `true` orders levels as they appear in the data.

Either input `Stat.color_discrete_hue` as an argument to `plot`, or set
`discrete_color_scale` in a [Theme](@ref Themes).

# Examples

```
julia> x = Scale.color_discrete_hue()
Gadfly.Scale.DiscreteColorScale(Gadfly.Scale.default_discrete_colors, nothing, nothing, true)

julia> x.f(3)
3-element Array{ColorTypes.Color,1}:
 LCHab{Float32}(70.0,60.0,240.0)
 LCHab{Float32}(80.0,70.0,100.435)
 LCHab{Float32}(65.8994,62.2146,353.998)
```
"""
color_discrete_hue(f=default_discrete_colors;
                   levels=nothing, order=nothing, preserve_order=true) =
        DiscreteColorScale(f, levels=levels, order=order, preserve_order=preserve_order)

@deprecate discrete_color_hue(; levels=nothing, order=nothing, preserve_order=true) color_discrete_hue(; levels=levels, order=order, preserve_order=preserve_order)

const color_discrete = color_discrete_hue   ### WHY HAVE THIS ALIAS?

@deprecate discrete_color(; levels=nothing, order=nothing, preserve_order=true) color_discrete(; levels=levels, order=order, preserve_order=preserve_order)


"""
    color_discrete_manual(colors...; levels=nothing, order=nothing)

Similar to [`color_discrete_hue`](@ref) except that colors for each level are
specified directly instead of being computed by a function.
"""
color_discrete_manual(colors::AbstractString...; levels=nothing, order=nothing) =
        color_discrete_manual(Gadfly.parse_colorant(colors)...; levels=levels, order=order)

function color_discrete_manual(colors::Color...; levels=nothing, order=nothing)
    cs = [colors...]
    f = n -> distinguishable_colors(n, cs)
    DiscreteColorScale(f, levels=levels, order=order)
end

@deprecate discrete_color_manual(colors...; levels=nothing, order=nothing) color_discrete_manual(colors...; levels=levels, order=order)

function apply_scale(scale::DiscreteColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    levelset = OrderedSet()
    for (aes, data) in zip(aess, datas)
        data.color === nothing && continue
        for d in data.color
            # Remove missing values
            # FixMe! The handling of missing values shouldn't be this scattered across the source
            ismissing(d) || push!(levelset, d)
        end
    end

    if scale.levels == nothing
        scale_levels = [levelset...]
        scale.preserve_order || sort!(scale_levels)
    else
        scale_levels = scale.levels
    end
    scale.order == nothing || permute!(scale_levels, scale.order)
    colors = convert(Vector{RGB{Float32}}, scale.f(length(scale_levels)))

    color_map = Dict([(color, string(label))
                              for (label, color) in zip(scale_levels, colors)])
    labeler(xs) = [color_map[x] for x in xs]

    for (aes, data) in zip(aess, datas)
        data.color === nothing && continue
        # Remove missing values
        # FixMe! The handling of missing values shouldn't be this scattered across the source
        ds = discretize([c for c in data.color if !ismissing(c)], scale_levels)

        colorvals = colors[ds.index]

        colored_ds = discretize_make_ia(colorvals, colors)
        aes.color = colored_ds

        aes.color_label = labeler
        aes.color_key_colors = OrderedDict()
        for (i, c) in enumerate(colors)
            aes.color_key_colors[c] = i
        end
    end
end


struct ContinuousColorScale <: Gadfly.ScaleElement
    # A function of the form f(p) where 0 <= p <= 1, that returns a color.
    f::Function
    trans::ContinuousScaleTransform

    minvalue
    maxvalue
end
ContinuousColorScale(f, trans=identity_transform; minvalue=nothing, maxvalue=nothing) =
        ContinuousColorScale(f, trans, minvalue, maxvalue)

function continuous_color_scale_partial(trans::ContinuousScaleTransform)
    lch_diverge2 = function(l0=30, l1=100, c=40, h0=260, h1=10, hmid=20, power=1.5)
        lspan = l1 - l0
        hspan1 = hmid - h0
        hspan0 = h1 - hmid
        function(r)
            r2 = 2r - 1
            return LCHab(min(80, l1 - lspan * abs(r2)^power), max(10, c * abs(r2)),
                         (1-r)*h0 + r * h1)
        end
    end

    function(; minvalue=nothing, maxvalue=nothing, colormap=lch_diverge2())
        ContinuousColorScale(colormap, trans, minvalue=minvalue, maxvalue=maxvalue)
    end
end

element_aesthetics(::ContinuousColorScale) = [:color]

"""
    color_continuous[(; minvalue=nothing, maxvalue=nothing, colormap)]

Create a continuous color scale by mapping
$(aes2str(element_aesthetics(color_continuous()))) to a `Color`.  `minvalue`
and `maxvalue` specify the data values corresponding to the bottom and top of
the color scale.  `colormap` is a function defined on the interval from 0 to 1
that returns a `Color`. See also [`lab_gradient`](@ref).

Either input `Stat.color_continuous` as an argument to `plot`, or
set `continuous_color_scale` in a [Theme](@ref Themes).

See also [`color_log10`](@ref), [`color_log2`](@ref), [`color_log`](@ref),
[`color_asinh`](@ref), and [`color_sqrt`](@ref).
"""
const color_continuous = continuous_color_scale_partial(identity_transform)

color_fun(fun) = """
    color_$(fun)[(; minvalue=nothing, maxvalue=nothing, colormap)]

Similar to [`Scale.color_continuous`](@ref), except that `color` is $(fun) transformed.
"""

for fun in [:log10, :log2, :log, :asinh, :sqrt]
  @eval @doc $(color_fun(fun)) const $(Symbol("color_",fun)) = continuous_color_scale_partial($(Symbol(fun,"_transform")))
end

const color_continuous_gradient = color_continuous  ### WHY HAVE THIS ALIAS?

@deprecate continuous_color_gradient(;minvalue=nothing, maxvalue=nothing) color_continuous_gradient(;minvalue=minvalue, maxvalue=maxvalue)

@deprecate continuous_color(;minvalue=nothing, maxvalue=nothing) color_continuous(;minvalue=nothing, maxvalue=nothing)

function apply_scale(scale::ContinuousColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    cdata = skipmissing(flatten(i.color for i in datas if i.color != nothing))
    if !isempty(cdata)
      cmin, cmax = extrema(cdata)
    else
        return
    end

    strict_span = false
    scale.minvalue != nothing && scale.maxvalue != nothing && (strict_span=true)
    scale.minvalue != nothing && (cmin=scale.minvalue)
    scale.maxvalue != nothing && (cmax=scale.maxvalue)

    cmin, cmax = promote(cmin, cmax)

    cmin = scale.trans.f(cmin)
    cmax = scale.trans.f(cmax)

    ticks, viewmin, viewmax = Gadfly.optimize_ticks(cmin, cmax, strict_span=strict_span)
    ticks[1] == 0 && cmin >= 1 && !strict_span && (ticks[1] = 1)

    cmin, cmax = ticks[1], ticks[end]
    cspan = cmax != cmin ? cmax - cmin : 1.0

    for (aes, data) in zip(aess, datas)
        data.color === nothing && continue

        aes.color = Array{RGB{Float32}}(undef, length(data.color))
        apply_scale_typed!(aes.color, data.color, scale, cmin, cspan)

        color_key_colors = Dict{Color, Float64}()
        color_key_labels = Dict{Color, AbstractString}()

        tick_labels = scale.trans.label(ticks)
        for (i, j, label) in zip(ticks, ticks[2:end], tick_labels[1:end-1])
            r = (i - cmin) / cspan
            c = scale.f(r)
            color_key_colors[c] = r
            color_key_labels[c] = label
        end
        c = scale.f((ticks[end] - cmin) / cspan)
        color_key_colors[c] = (ticks[end] - cmin) / cspan
        color_key_labels[c] = tick_labels[end]

        labeler(xs) = [get(color_key_labels, x, "") for x in xs]

        aes.color_function = scale.f
        aes.color_label = labeler
        aes.color_key_colors = color_key_colors
        aes.color_key_continuous = true
    end
end

function apply_scale_typed!(ds, field, scale::ContinuousColorScale,
                            cmin, cspan)
    for (i, d) in enumerate(field)
        if isconcrete(d)
            ds[i] = convert(RGB{Float32},
                        scale.f((scale.trans.f(d) - cmin) / cspan))
        else
            ds[i] = missing
        end
    end
end


# Label scale is always discrete, hence we call it 'label' rather
# 'label_discrete'.
struct LabelScale <: Gadfly.ScaleElement
end

function apply_scale(scale::LabelScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        data.label === nothing && continue
        aes.label = discretize(data.label)
    end
end

element_aesthetics(::LabelScale) = [:label]

"""
   label
"""
const label = LabelScale


"""
    xgroup[(; labels=nothing, levels=nothing, order=nothing)]

A discrete scale for use with [`Geom.subplot_grid`](@ref Gadfly.Geom.subplot_grid).
"""
xgroup(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:xgroup], labels=labels, levels=levels, order=order)

"""
    ygroup[(; labels=nothing, levels=nothing, order=nothing)]

A discrete scale for use with [`Geom.subplot_grid`](@ref Gadfly.Geom.subplot_grid).
"""
ygroup(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:ygroup], labels=labels, levels=levels, order=order)


# Catchall scale for when no transformation of the data is necessary
struct IdentityScale <: Gadfly.ScaleElement
    var::Symbol
end

element_aesthetics(scale::IdentityScale) = [scale.var]

function apply_scale(scale::IdentityScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        getfield(data, scale.var) === nothing && continue
        setfield!(aes, scale.var, getfield(data, scale.var))
    end
end

### could these be defined as `const z_func = ` ?
"""
    z_func()
"""
z_func() = IdentityScale(:z)

"""
    y_func()
"""
y_func() = IdentityScale(:y)

"""
    x_distribution()
"""
x_distribution() = IdentityScale(:x)

"""
    y_distribution()
"""
y_distribution() = IdentityScale(:y)

"""
    shape_identity()
"""
shape_identity() = IdentityScale(:shape)

"""
    size_identity()
"""
size_identity() = IdentityScale(:size)

end # module Scale
