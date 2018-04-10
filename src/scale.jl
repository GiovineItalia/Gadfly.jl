module Scale

using Colors
using Compat
using Compose
using DataArrays
using DataStructures
using Gadfly
using Showoff
using IndirectArrays
using CategoricalArrays

import Gadfly: element_aesthetics, isconcrete, concrete_length, discretize_make_ia
import Distributions: Distribution

include("color_misc.jl")

# Return true if var is categorical.
iscategorical(scales::Dict{Symbol, Gadfly.ScaleElement}, var::Symbol) =
        haskey(scales, var) && isa(scales[var], DiscreteScale)

# Apply some scales to data in the given order.
#
# Args:
#   scales: An iterable object of ScaleElements.
#   aess: Aesthetics (of the same length as datas) to update with scaled data.
#   datas: Zero or more data objects. (Yes, I know "datas" is not a real word.)
#
# Returns:
#   nothing
#
function apply_scales(scales, aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for scale in scales
        apply_scale(scale, aess, datas...)
    end

    for (aes, data) in zip(aess, datas)
        aes.titles = data.titles
    end
end

# Apply some scales to data in the given order.
#
# Args:
#   scales: An iterable object of ScaleElements.
#   datas: Zero or more data objects.
#
# Returns:
#   A vector of Aesthetics of the same length as datas containing scaled data.
#
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

ln_formatter(xs::AbstractArray, format=:plain) =
        [@sprintf("e<sup>%s</sup>", x) for x in showoff(xs, format)]
const ln_transform = ContinuousScaleTransform(log, exp, ln_formatter)

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
    labels::Union{(Void), Function}
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

const x_vars = [:x, :xmin, :xmax, :xintercept, :intercept, :xviewmin, :xviewmax, :xend]
const y_vars = [:y, :ymin, :ymax, :yintercept, :slope, :middle, :upper_fence, :lower_fence,
                :upper_hinge, :lower_hinge, :yviewmin, :yviewmax, :yend]

function continuous_scale_partial(vars::Vector{Symbol}, trans::ContinuousScaleTransform)
    function(; minvalue=nothing, maxvalue=nothing, labels=nothing, format=nothing, minticks=2,
                 maxticks=10, scalable=true)
        ContinuousScale(vars, trans, minvalue=minvalue, maxvalue=maxvalue,
                        labels=labels, format=format, minticks=minticks,
                        maxticks=maxticks, scalable=scalable)
    end
end

# Commonly used scales.
"""
    Scale.x_continous[(; minvalue, maxvalue, labels, format,
                       minticks, maxticks, scalable)]

Map numerical data to x positions in cartesian coordinates.

# Arguments
- `minvalue`: Set scale lower bound to be ≤ this value.
- `maxvalue`: Set scale lower bound to be ≥ this value.

!!! note

    `minvalue` and `maxvalue` here are soft bounds, Gadfly may choose to ignore
    them when constructing an optimal plot. Use [`Coord.cartesian`](@ref) to enforce
    a hard bound.

- `labels`: Either a `Function` or `nothing`. When a
    function is given, values are formatted using this function. The function
    should map a value in `x` to a string giving its label. If the scale
    applies a transformation, transformed label values will be passed to this
    function.
- `format`: How numbers should be formatted. One of `:plain`, `:scientific`,
    `:engineering`, or `:auto`. The default in `:auto` which prints very large or very small
    numbers in scientific notation, and other numbers plainly.
- `scalable`: When set to false, scale is fixed when zooming (default: true)

# Variations
A number of transformed continuous scales are provided.

- `Scale.x_continuous` (scale without any transformation).
- `Scale.x_log10`
- `Scale.x_log2`
- `Scale.x_log`
- `Scale.x_asinh`
- `Scale.x_sqrt`


# Aesthetics Acted On
`x`, `xmin`, `xmax`, `xintercept`
"""
const x_continuous = continuous_scale_partial(x_vars, identity_transform)

"""
    Scale.y_continuous[(; minvalue, maxvalue, labels, format,
                       minticks, maxticks, scalable)]

Map numerical data to y positions in cartesian coordinates.

# Arguments
- `minvalue`: Set scale lower bound to be ≤ this value.
- `maxvalue`: Set scale lower bound to be ≥ this value.

!!! note

    `minvalue` and `maxvalue` here are soft bounds, Gadfly may choose to ignore
    them when constructing an optimal plot. Use [`Coord.cartesian`](@ref) to enforce
    a hard bound.

- `labels`: Either a `Function` or `nothing`. When a
    function is given, values are formatted using this function. The function
    should map a value in `x` to a string giving its label. If the scale
    applies a transformation, transformed label values will be passed to this
    function.
- `format`: How numbers should be formatted. One of `:plain`, `:scientific`,
    `:engineering`, or `:auto`. The default in `:auto` which prints very large or very small
    numbers in scientific notation, and other numbers plainly.
- `scalable`: When set to false, scale is fixed when zooming (default: true)

# Variations
A number of transformed continuous scales are provided.

- `Scale.y_continuous` (scale without any transformation).
- `Scale.y_log10`
- `Scale.y_log2`
- `Scale.y_log`
- `Scale.y_asinh`
- `Scale.y_sqrt`


# Aesthetics
`y`, `ymin`, `ymax`, `yintercept`
"""
const y_continuous = continuous_scale_partial(y_vars, identity_transform)
const x_log10      = continuous_scale_partial(x_vars, log10_transform)
const y_log10      = continuous_scale_partial(y_vars, log10_transform)
const x_log2       = continuous_scale_partial(x_vars, log2_transform)
const y_log2       = continuous_scale_partial(y_vars, log2_transform)
const x_log        = continuous_scale_partial(x_vars, ln_transform)
const y_log        = continuous_scale_partial(y_vars, ln_transform)
const x_asinh      = continuous_scale_partial(x_vars, asinh_transform)
const y_asinh      = continuous_scale_partial(y_vars, asinh_transform)
const x_sqrt       = continuous_scale_partial(x_vars, sqrt_transform)
const y_sqrt       = continuous_scale_partial(y_vars, sqrt_transform)

const size_continuous = continuous_scale_partial([:size], identity_transform)

element_aesthetics(scale::ContinuousScale) = scale.vars

# Apply a continuous scale.
#
# Args:
#   scale: A continuous scale.
#   datas: Zero or more data objects.
#   aess: Aesthetics (of the same length as datas) to update with scaled data.
#
# Return:
#   nothing
#
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
            if var == :y && eltype(vals) == Function
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

            if T <: Measure
                T = Measure
            end

            ds = any(ismissing, vals) ? DataArray(T, length(vals)) : Array{T}(length(vals))
            apply_scale_typed!(ds, vals, scale)

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

            if in(label_var, Set(fieldnames(aes)))
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

    # Labels are either a function that takes an array of values and returns
    # an array of string labels, a vector of string labels of the same length
    # as the number of unique values in the discrete data, or nothing to use
    # the default labels.
    labels::Union{(Void), Function}

    # If non-nothing, give values for the scale. Order will be respected and
    # anything in the data that's not represented in values will be set to missing.
    levels::Union{(Void), AbstractVector}

    # If non-nothing, a permutation of the pool of values.
    order::Union{(Void), AbstractVector}
end
DiscreteScale(vals; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale(vals, labels, levels, order)

const discrete = DiscreteScale

element_aesthetics(scale::DiscreteScale) = scale.vars

"""
  Scale.x_discrete[(; labels, levels, order)]

Map data categorical to Cartesian coordinates. Unlike [`Scale.x_continuous`](@ref), each
unique x value will be mapped to a equally spaced positions, regardless of
value.

By default continuous scales are applied to numerical data. If data consists of
numbers specifying categories, explicitly adding [`Scale.x_discrete`](@ref) is the
easiest way to get that data to plot appropriately.

# Arguments
- `labels`: Either a `Function` or `nothing`. When a
    function is given, values are formatted using this function. The function
    should map a value in `x` to a string giving its label.
- `levels`: If non-nothing, give values for the scale. Order will be respected
    and anything in the data that's not respresented in `levels` will be set to
    `missing`.
- `order`: If non-nothing, give a vector of integers giving a permutation of
    the values pool of the data.

# Aesthetics

`x`, `xmin`, `xmax`, `xintercept`
"""
x_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale(x_vars, labels=labels, levels=levels, order=order)

"""
    Scale.y_discrete[(; labels, levels, order)]

Map data categorical to Cartesian coordinates. Unlike [`Scale.y_continuous`](@ref), each
unique y value will be mapped to a equally spaced positions, regardless of
value.

By default continuous scales are applied to numerical data. If data consists of
numbers specifying categories, explicitly adding [`Scale.y_discrete`](@ref) is the
easiest way to get that data to plot appropriately.

# Arguments
- `labels`: Either a `Function` or `nothing`. When a
    function is given, values are formatted using this function. The function
    should map a value in `x` to a string giving its label.
- `levels`: If non-nothing, give values for the scale. Order will be respected
    and anything in the data that's not respresented in `levels` will be set to
    `missing`.
- `order`: If non-nothing, give a vector of integers giving a permutation of
    the values pool of the data.

# Aesthetics
`y`, `ymin`, `ymax`, `yintercept`
"""
y_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale(y_vars, labels=labels, levels=levels, order=order)

group_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:group], labels=labels, levels=levels, order=order)

shape_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:shape], labels=labels, levels=levels, order=order)

size_discrete(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:size], labels=labels, levels=levels, order=order)

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

            in(label_var, Set(fieldnames(aes))) && setfield!(aes, label_var, labeler)
        end
    end
end


struct NoneColorScale <: Gadfly.ScaleElement
end

"""
    Scale.color_none

Suppress a default color scale. Some statistics impose a default color scale.
When no color scale is desired, explicitly including [`Scale.color_none`](@ref) will
suppress this default.

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
    f::Function # A function f(n) that produces a vector of n colors.

    # If non-nothing, give values for the scale. Order will be respected and
    # anything in the data that's not represented in values will be set to missing.
    levels::Union{(Void), AbstractVector}

    # If non-nothing, a permutation of the pool of values.
    order::Union{(Void), AbstractVector}

    # If true, order levels as they appear in the data
    preserve_order::Bool
end
DiscreteColorScale(f; levels=nothing, order=nothing, preserve_order=true) =
        DiscreteColorScale(f, levels, order, preserve_order)

element_aesthetics(scale::DiscreteColorScale) = [:color]

function default_discrete_colors(n)
    convert(Vector{Color},
         distinguishable_colors(n, [LCHab(70, 60, 240)],
             transform=c -> deuteranopic(c, 0.5),
             lchoices=Float64[65, 70, 75, 80],
             cchoices=Float64[0, 50, 60, 70],
             hchoices=linspace(0, 330, 24),
         )
     )
end

# Common discrete color scales
"""
    Scale.color_discrete_hue[(f; levels, order, preserve_order)]

Create a discrete color scale to be used for the plot. `Scale.color_discrete` is an
alias for [`Scale.color_discrete_hue`](@ref).

# Arguments
- `f`: A function `f(n)` that produces a vector of `n` colors. Usually [`distinguishable_colors`](https://github.com/JuliaGraphics/Colors.jl#distinguishable_colors) can be used for this, with parameters tuned to your liking.
- `levels`: Explicitly set levels used by the scale.
- `order`: A vector of integers giving a permutation of the levels
    default order.
- `preserve_order`: If set to `true`, orders levels as they appear in the data
"""
function color_discrete_hue(f=default_discrete_colors;
                            levels=nothing,
                            order=nothing,
                            preserve_order=true)
    DiscreteColorScale(
        f,
        levels=levels,
        order=order,
        preserve_order=preserve_order)
end

@deprecate discrete_color_hue(; levels=nothing, order=nothing, preserve_order=true) color_discrete_hue(; levels=levels, order=order, preserve_order=preserve_order)

const color_discrete = color_discrete_hue

@deprecate discrete_color(; levels=nothing, order=nothing, preserve_order=true) color_discrete(; levels=levels, order=order, preserve_order=preserve_order)

"""
    Scale.color_discrete_manual[(; colors, levels, order)]

Create a discrete color scale to be used for the plot.

# Arguments
- `colors...`: an iterable collection of things that can be converted to colors with `Colors.color` (e.g. "tomato", RGB(1.0,0.388,0.278), colorant"#FF6347")
- `levels` (optional): Explicitly set levels used by the scale. Order is
    respected.
- `order` (optional): A vector of integers giving a permutation of the levels
    default order.

# Aesthetics Acted On
`color`
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

# Commonly used scales.
"""
    Scale.color_continuous[(; minvalue, maxvalue, colormap)]

Create a continuous color scale that the plot will use.

This can also be set as the `continuous_color_scheme` in a Theme (see [Themes](@ref)).

# Arguments
- `minvalue` (optional): the data value corresponding to the bottom of the color scale (will be based on the range of the data if not specified).
- `maxvalue` (optional): the data value corresponding to the top of the color scale (will be based on the range of the data if not specified).
- `colormap`: A function defined on the interval from 0 to 1 that returns a `Color` (as from the `Colors` package).

# Variations

`color_continuous_gradient` is an alias for [`Scale.color_continuous`](@ref).

A number of transformed continuous scales are provided.

- `Scale.color_continuous` (scale without any transformation).
- `Scale.color_log10`
- `Scale.color_log2`
- `Scale.color_log`
- `Scale.color_asinh`
- `Scale.color_sqrt`

# Aesthetics Acted On
`color`
"""
const color_continuous = continuous_color_scale_partial(identity_transform)
const color_log10      = continuous_color_scale_partial(log10_transform)
const color_log2       = continuous_color_scale_partial(log2_transform)
const color_log        = continuous_color_scale_partial(ln_transform)
const color_asinh      = continuous_color_scale_partial(asinh_transform)
const color_sqrt       = continuous_color_scale_partial(sqrt_transform)

const color_continuous_gradient = color_continuous

element_aesthetics(::ContinuousColorScale) = [:color]

@deprecate continuous_color_gradient(;minvalue=nothing, maxvalue=nothing) color_continuous_gradient(;minvalue=minvalue, maxvalue=maxvalue)

@deprecate continuous_color(;minvalue=nothing, maxvalue=nothing) color_continuous(;minvalue=nothing, maxvalue=nothing)

function apply_scale(scale::ContinuousColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    cmin, cmax = Inf, -Inf
    for data in datas
        data.color === nothing && continue

        for c in data.color
            ismissing(c) && continue

            c = convert(Float64, c)
            if c < cmin
                cmin = c
            end

            if c > cmax
                cmax = c
            end
        end
    end

    (cmin == Inf || cmax == -Inf) && return

    if scale.minvalue != nothing
        cmin = scale.minvalue
    end

    if scale.maxvalue  != nothing
        cmax = scale.maxvalue
    end

    cmin, cmax = promote(cmin, cmax)

    cmin = scale.trans.f(cmin)
    cmax = scale.trans.f(cmax)

    ticks, viewmin, viewmax = Gadfly.optimize_ticks(cmin, cmax)
    if ticks[1] == 0 && cmin >= 1
        ticks[1] = 1
    end

    cmin, cmax = ticks[1], ticks[end]
    cspan = cmax != cmin ? cmax - cmin : 1.0

    for (aes, data) in zip(aess, datas)
        data.color === nothing && continue

        aes.color = Array{RGB{Float32}}(length(data.color))
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
                            cmin::Float64, cspan::Float64)
    for (i, d) in enumerate(field)
        if isconcrete(d)
            ds[i] = convert(RGB{Float32},
                        scale.f((convert(Float64, scale.trans.f(d)) - cmin) / cspan))
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

const label = LabelScale


# Scale applied to grouping aesthetics.
struct GroupingScale <: Gadfly.ScaleElement
    var::Symbol
end

xgroup(; labels=nothing, levels=nothing, order=nothing) =
        DiscreteScale([:xgroup], labels=labels, levels=levels, order=order)

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

z_func() = IdentityScale(:z)
y_func() = IdentityScale(:y)
x_distribution() = IdentityScale(:x)
y_distribution() = IdentityScale(:y)
shape_identity() = IdentityScale(:shape)
size_identity() = IdentityScale(:size)

end # module Scale
