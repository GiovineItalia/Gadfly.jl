
module Scale

using Colors
using Compat
using Compose
using DataArrays
using DataStructures
using Gadfly
using Showoff

import Gadfly: element_aesthetics, isconcrete, concrete_length,
               nonzero_length
import Distributions: Distribution

include("color_misc.jl")


# Return true if var is categorical.
function iscategorical(scales::Dict{Symbol, Gadfly.ScaleElement}, var::Symbol)
    return haskey(scales, var) && isa(scales[var], DiscreteScale)
end


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
function apply_scales(scales,
                      aess::Vector{Gadfly.Aesthetics},
                      datas::Gadfly.Data...)
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
immutable ContinuousScaleTransform
    f::Function     # transform function
    finv::Function  # f's inverse

    # A function taking one or more values and returning an array of
    # strings.
    label::Function
end


function identity_formatter(xs::AbstractArray, format=:auto)
    return showoff(xs, format)
end

const identity_transform =
    ContinuousScaleTransform(identity, identity, identity_formatter)

function log10_formatter(xs::AbstractArray, format=:plain)
    [@sprintf("10<sup>%s</sup>", x) for x in showoff(xs, format)]
end

const log10_transform =
    ContinuousScaleTransform(log10, x -> 10^x, log10_formatter)


function log2_formatter(xs::AbstractArray, format=:plain)
    [@sprintf("2<sup>%s</sup>", x) for x in showoff(xs, format)]
end

const log2_transform =
    ContinuousScaleTransform(log2, x -> 2^x, log2_formatter)


function ln_formatter(xs::AbstractArray, format=:plain)
    [@sprintf("e<sup>%s</sup>", x) for x in showoff(xs, format)]
end

const ln_transform =
    ContinuousScaleTransform(log, exp, ln_formatter)


function asinh_formatter(xs::AbstractArray, format=:plain)
    [@sprintf("sinh(%s)", x) for x in showoff(xs, format)]
end

const asinh_transform =
    ContinuousScaleTransform(asinh, sinh, asinh_formatter)


function sqrt_formatter(xs::AbstractArray, format=:plain)
    [@sprintf("%s<sup>2</sup>", x) for x in showoff(xs, format)]
end

const sqrt_transform = ContinuousScaleTransform(sqrt, x -> x^2, sqrt_formatter)


# Continuous scale maps data on a continuous scale simple by calling
# `convert(Float64, ...)`.
immutable ContinuousScale <: Gadfly.ScaleElement
    vars::Vector{Symbol}
    trans::ContinuousScaleTransform
    minvalue
    maxvalue
    minticks
    maxticks
    labels::@compat(Union{(@compat Void), Function})
    format
    scalable

    function ContinuousScale(vars::Vector{Symbol},
                             trans::ContinuousScaleTransform;
                             labels=nothing,
                             minvalue=nothing, maxvalue=nothing,
                             minticks=2, maxticks=10,
                             format=nothing,
                             scalable=true)
        if minvalue != nothing && maxvalue != nothing && minvalue > maxvalue
            error("Cannot construct a ContinuousScale with minvalue > maxvalue")
        end
        new(vars, trans, minvalue, maxvalue, minticks, maxticks, labels,
            format, scalable)
    end
end


function make_labeler(scale::ContinuousScale)
    if scale.labels != nothing
        function(xs)
            return [scale.labels(x) for x in xs]
        end
    elseif scale.format == nothing
        scale.trans.label
    else
        function(xs)
            return scale.trans.label(xs, scale.format)
        end
    end
end


const x_vars = [:x, :xmin, :xmax, :xintercept, :xviewmin, :xviewmax, :xend]
const y_vars = [:y, :ymin, :ymax, :yintercept, :middle,
                :upper_fence, :lower_fence, :upper_hinge, :lower_hinge,
    :yviewmin, :yviewmax, :yend]

function continuous_scale_partial(vars::Vector{Symbol},
                                  trans::ContinuousScaleTransform)
    function f1(; minvalue=nothing, maxvalue=nothing, labels=nothing, format=nothing, minticks=2,
                 maxticks=10, scalable=true)
        ContinuousScale(vars, trans, minvalue=minvalue, maxvalue=maxvalue,
                        labels=labels, format=format, minticks=minticks,
                        maxticks=maxticks, scalable=scalable)
    end
end


# Commonly used scales.
const x_continuous = continuous_scale_partial(x_vars, identity_transform)
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


function element_aesthetics(scale::ContinuousScale)
    return scale.vars
end


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
            if vals === nothing
                continue
            end

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

            ds = Gadfly.hasna(vals) ? DataArray(T, length(vals)) : Array(T, length(vals))
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

# Reorder the levels of a pooled data array
function reorder_levels(da::PooledDataArray, order::AbstractVector)
    level_values = levels(da)
    if length(order) != length(level_values)
        error("Discrete scale order is not of the same length as the data's levels.")
    end
    permute!(level_values, order)
    return PooledDataArray(da, level_values)
end


function discretize_make_pda(values::Vector, levels=nothing)
    if levels == nothing
        return PooledDataArray(values)
    else
        return PooledDataArray(convert(Vector{eltype(levels)}, values), levels)
    end
end


function discretize_make_pda(values::DataArray, levels=nothing)
    if levels == nothing
        return PooledDataArray(values)
    else
        return PooledDataArray(convert(DataArray{eltype(levels)}, values), levels)
    end
end


function discretize_make_pda(values::Range, levels=nothing)
    if levels == nothing
        return PooledDataArray(collect(values))
    else
        return PooledDataArray(collect(values), levels)
    end
end


function discretize_make_pda(values::PooledDataArray, levels=nothing)
    if levels == nothing
        return values
    else
        return PooledDataArray(values, convert(Vector{eltype(values)}, levels))
    end
end


function discretize(values, levels=nothing, order=nothing,
                    preserve_order=true)
    if levels == nothing
        if preserve_order
            levels = OrderedSet()
            for value in values
                push!(levels, value)
            end
            da = discretize_make_pda(values, collect(eltype(values), levels))
        else
            da = discretize_make_pda(values)
        end
    else
        da = discretize_make_pda(values, levels)
    end

    if order != nothing
        return reorder_levels(da, order)
    else
        return da
    end
end


immutable DiscreteScaleTransform
    f::Function
end


immutable DiscreteScale <: Gadfly.ScaleElement
    vars::Vector{Symbol}

    # Labels are either a function that takes an array of values and returns
    # an array of string labels, a vector of string labels of the same length
    # as the number of unique values in the discrete data, or nothing to use
    # the default labels.
    labels::@compat(Union{(@compat Void), Function})

    # If non-nothing, give values for the scale. Order will be respected and
    # anything in the data that's not represented in values will be set to NA.
    levels::@compat(Union{(@compat Void), AbstractVector})

    # If non-nothing, a permutation of the pool of values.
    order::@compat(Union{(@compat Void), AbstractVector})

    function DiscreteScale(vals::Vector{Symbol};
                           labels=nothing, levels=nothing, order=nothing)
        new(vals, labels, levels, order)
    end
end

const discrete = DiscreteScale


element_aesthetics(scale::DiscreteScale) = scale.vars


function x_discrete(; labels=nothing, levels=nothing, order=nothing)
    return DiscreteScale(x_vars, labels=labels, levels=levels, order=order)
end


function y_discrete(; labels=nothing, levels=nothing, order=nothing)
    return DiscreteScale(y_vars, labels=labels, levels=levels, order=order)
end


function group_discrete(; labels=nothing, levels=nothing, order=nothing)
    return DiscreteScale([:group], labels=labels, levels=levels, order=order)
end


function shape_discrete(; labels=nothing, levels=nothing, order=nothing)
    return DiscreteScale([:shape], labels=labels, levels=levels, order=order)
end


function apply_scale(scale::DiscreteScale, aess::Vector{Gadfly.Aesthetics},
                     datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        for var in scale.vars
            label_var = Symbol(var, "_label")

            if getfield(data, var) === nothing
                continue
            end

            disc_data = discretize(getfield(data, var), scale.levels, scale.order)

            setfield!(aes, var, PooledDataArray(round(Int64, disc_data.refs)))

            # The leveler for discrete scales is a closure over the discretized data.
            if scale.labels === nothing
                function default_labeler(xs)
                    lvls = levels(disc_data)
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
                    lvls = levels(disc_data)
                    return [string(scale.labels(lvls[x])) for x in xs]
                end

                labeler = explicit_labeler
            end

            if in(label_var, Set(fieldnames(aes)))
                setfield!(aes, label_var, labeler)
            end
        end
    end
end


immutable NoneColorScale <: Gadfly.ScaleElement
end


const color_none = NoneColorScale


function element_aesthetics(scale::NoneColorScale)
    [:color]
end


function apply_scale(scale::NoneColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for aes in aess
        aes.color = nothing
    end
end


immutable DiscreteColorScale <: Gadfly.ScaleElement
    f::Function # A function f(n) that produces a vector of n colors.

    # If non-nothing, give values for the scale. Order will be respected and
    # anything in the data that's not represented in values will be set to NA.
    levels::@compat(Union{(@compat Void), AbstractVector})

    # If non-nothing, a permutation of the pool of values.
    order::@compat(Union{(@compat Void), AbstractVector})

    # If true, order levels as they appear in the data
    preserve_order::Bool

    function DiscreteColorScale(f::Function; levels=nothing, order=nothing,
                                preserve_order=true)
        new(f, levels, order, preserve_order)
    end
end


function element_aesthetics(scale::DiscreteColorScale)
    [:color]
end


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
function color_discrete_hue(f=default_discrete_colors;
                            levels=nothing,
                            order=nothing,
                            preserve_order=true)

    DiscreteColorScale(
        default_discrete_colors,
        levels=levels,
        order=order,
        preserve_order=preserve_order,
    )
end

@deprecate discrete_color_hue(; levels=nothing, order=nothing, preserve_order=true) color_discrete_hue(; levels=levels, order=order, preserve_order=preserve_order)


const color_discrete = color_discrete_hue

@deprecate discrete_color(; levels=nothing, order=nothing, preserve_order=true) color_discrete(; levels=levels, order=order, preserve_order=preserve_order)


color_discrete_manual(colors::AbstractString...; levels=nothing, order=nothing) = color_discrete_manual(map(Gadfly.parse_colorant, colors)...; levels=levels, order=order)

function color_discrete_manual(colors::Color...; levels=nothing, order=nothing)
    cs = [colors...]
    f = function(n)
        distinguishable_colors(n, cs)
    end
    DiscreteColorScale(f, levels=levels, order=order)
end

@deprecate discrete_color_manual(colors...; levels=nothing, order=nothing) color_discrete_manual(colors...; levels=levels, order=order)


function apply_scale(scale::DiscreteColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    levelset = OrderedSet()
    for (aes, data) in zip(aess, datas)
        if data.color === nothing
            continue
        end
        for d in data.color
            if !isna(d)
                push!(levelset, d)
            end
        end
    end

    if scale.levels == nothing
        scale_levels = [levelset...]
        if !scale.preserve_order
            sort!(scale_levels)
        end
    else
        scale_levels = scale.levels
    end
    if scale.order != nothing
        permute!(scale_levels, scale.order)
    end
    colors = convert(Vector{RGB{Float32}}, scale.f(length(scale_levels)))

    color_map = @compat Dict([(color, string(label))
                              for (label, color) in zip(scale_levels, colors)])
    function labeler(xs)
        [color_map[x] for x in xs]
    end

    for (aes, data) in zip(aess, datas)
        if data.color === nothing
            continue
        end
        ds = discretize(data.color, scale_levels)
        colorvals = Array(RGB{Float32}, nonzero_length(ds.refs))
        i = 1
        for k in ds.refs
            if k != 0
                colorvals[i] = colors[k]
                i += 1
            end
        end

        colored_ds = PooledDataArray(colorvals, colors)
        aes.color = colored_ds

        aes.color_label = labeler
        aes.color_key_colors = OrderedDict()
        for (i, c) in enumerate(colors)
            aes.color_key_colors[c] = i
        end
    end
end


immutable ContinuousColorScale <: Gadfly.ScaleElement
    # A function of the form f(p) where 0 <= p <= 1, that returns a color.
    f::Function
    trans::ContinuousScaleTransform

    minvalue
    maxvalue

    function ContinuousColorScale(f::Function, trans::ContinuousScaleTransform=identity_transform; minvalue=nothing, maxvalue=nothing)
        new(f, trans, minvalue, maxvalue)
    end
end


function continuous_color_scale_partial(trans::ContinuousScaleTransform)
    lch_diverge2 = function f3(l0=30, l1=100, c=40, h0=260, h1=10, hmid=20, power=1.5)
        lspan = l1 - l0
        hspan1 = hmid - h0
        hspan0 = h1 - hmid
        function(r)
            r2 = 2r - 1
            return LCHab(min(80, l1 - lspan * abs(r2)^power), max(10, c * abs(r2)),
                         (1-r)*h0 + r * h1)
        end
    end

    function f2(; minvalue=nothing, maxvalue=nothing, colormap=lch_diverge2())
        ContinuousColorScale(colormap, trans, minvalue=minvalue, maxvalue=maxvalue)
    end
end


# Commonly used scales.
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
    cmin = Inf
    cmax = -Inf
    for data in datas
        if data.color === nothing
            continue
        end

        for c in data.color
            if c === NA
                continue
            end

            c = convert(Float64, c)
            if c < cmin
                cmin = c
            end

            if c > cmax
                cmax = c
            end
        end
    end

    if cmin == Inf || cmax == -Inf
        return nothing
    end

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

    cmin = ticks[1]
    cmax = ticks[end]
    cspan = cmax != cmin ? cmax - cmin : 1.0

    for (aes, data) in zip(aess, datas)
        if data.color === nothing
            continue
        end

        aes.color = DataArray(RGB{Float32}, length(data.color))
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

        function labeler(xs)
            [get(color_key_labels, x, "") for x in xs]
        end

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
            ds[i] = convert(RGB{Float32}, scale.f((convert(Float64, scale.trans.f(d)) - cmin) / cspan))
        else
            ds[i] = NA
        end
    end
end


# Label scale is always discrete, hence we call it 'label' rather
# 'label_discrete'.
immutable LabelScale <: Gadfly.ScaleElement
end


function apply_scale(scale::LabelScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        if data.label === nothing
            continue
        end

        aes.label = discretize(data.label)
    end
end


element_aesthetics(::LabelScale) = [:label]


const label = LabelScale


# Scale applied to grouping aesthetics.
immutable GroupingScale <: Gadfly.ScaleElement
    var::Symbol
end


function xgroup(; labels=nothing, levels=nothing, order=nothing)
    return DiscreteScale([:xgroup], labels=labels, levels=levels, order=order)
end


function ygroup(; labels=nothing, levels=nothing, order=nothing)
    return DiscreteScale([:ygroup], labels=labels, levels=levels, order=order)
end


# Catchall scale for when no transformation of the data is necessary
immutable IdentityScale <: Gadfly.ScaleElement
    var::Symbol
end


function element_aesthetics(scale::IdentityScale)
    return [scale.var]
end


function apply_scale(scale::IdentityScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        if getfield(data, scale.var) === nothing
            continue
        end

        setfield!(aes, scale.var, getfield(data, scale.var))
    end
end


function z_func()
    return IdentityScale(:z)
end


function y_func()
    return IdentityScale(:y)
end


function x_distribution()
    return IdentityScale(:x)
end


function y_distribution()
    return IdentityScale(:y)
end


end # module Scale
