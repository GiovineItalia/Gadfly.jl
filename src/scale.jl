
module Scale

using Color
using Compose
using DataFrames
using Gadfly

import Gadfly.element_aesthetics, Gadfly.isconcrete, Gadfly.concrete_length,
       Gadfly.nonzero_length

include("color.jl")

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
    aess = [Gadfly.Aesthetics() for _ in datas]
    apply_scales(scales, aess, datas...)
    aess
end


# Transformations on continuous scales
type ContinuousScaleTransform
    f::Function     # transform function
    finv::Function  # f's inverse
    label::Function # produce a string given some value f(x)
end

const identity_transform =
    ContinuousScaleTransform(identity, identity, Gadfly.fmt_float)
const log10_transform =
    ContinuousScaleTransform(log10, x -> 10^x,
                             x -> @sprintf("10<sup>%s</sup>", Gadfly.fmt_float(x)))
const log2_transform =
    ContinuousScaleTransform(log10, x -> 2^x,
                             x -> @sprintf("2<sup>%s</sup>", Gadfly.fmt_float(x)))
const ln_transform =
    ContinuousScaleTransform(log, exp,
                             x -> @sprintf("e<sup>%s</sup>", Gadfly.fmt_float(x)))
const asinh_transform =
    ContinuousScaleTransform(asinh, sinh, x -> Gadfly.fmt_float(sinh(x)))
const sqrt_transform =
    ContinuousScaleTransform(sqrt, x -> x^2,
                             x -> @sprintf("√%s", Gadfly.fmt_float(x)))


# Continuous scale maps data on a continuous scale simple by calling
# `convert(Float64, ...)`.
type ContinuousScale <: Gadfly.ScaleElement
    vars::Vector{Symbol}
    trans::ContinuousScaleTransform
end

const x_vars = [:x, :x_min, :x_max]
const y_vars = [:y, :y_min, :y_max]

# Commonly used scales.
const x_continuous = ContinuousScale(x_vars, identity_transform)
const y_continuous = ContinuousScale(y_vars, identity_transform)
const x_log10      = ContinuousScale(x_vars, log10_transform)
const y_log10      = ContinuousScale(y_vars, log10_transform)
const x_log2       = ContinuousScale(x_vars, log2_transform)
const y_log2       = ContinuousScale(y_vars, log2_transform)
const x_log        = ContinuousScale(x_vars, ln_transform)
const y_log        = ContinuousScale(y_vars, ln_transform)
const x_asinh      = ContinuousScale(x_vars, asinh_transform)
const y_asinh      = ContinuousScale(y_vars, asinh_transform)
const x_sqrt       = ContinuousScale(x_vars, sqrt_transform)
const y_sqrt       = ContinuousScale(y_vars, sqrt_transform)


function element_aesthetics(scale::ContinuousScale)
    return scale.vars
end


# Apply a continuous scale.
#
# Args:
#   scale: A continuos scale.
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
            label_var = symbol(@sprintf("%s_label", string(var)))
            if getfield(data, var) === nothing
                continue
            end

            ds = Array(Float64, concrete_length(getfield(data, var)))
            i = 1
            for d in getfield(data, var)
                if isconcrete(d)
                    ds[i] = scale.trans.f(convert(Float64, d))
                    i += 1
                end
            end

            setfield(aes, var, ds)
            if contains(Set(names(aes)...), label_var)
                setfield(aes, label_var, scale.trans.label)
            end
        end
    end
end


discretize(values::Vector) = PooledDataArray(values)
discretize(values::DataArray) = PooledDataArray(values)
discretize(values::PooledDataArray) = values


type DiscreteScaleTransform
    f::Function
end


type DiscreteScale <: Gadfly.ScaleElement
    vars::Vector{Symbol}
end


element_aesthetics(scale::DiscreteScale) = scale.vars


const x_discrete = DiscreteScale(x_vars)
const y_discrete = DiscreteScale(y_vars)


function apply_scale(scale::DiscreteScale, aess::Vector{Gadfly.Aesthetics},
                     datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        for var in scale.vars
            label_var = symbol(@sprintf("%s_label", string(var)))

            if getfield(data, var) === nothing
                continue
            end

            disc_data = discretize(getfield(data, var))
            setfield(aes, var, Int64[r for r in disc_data.refs])

            # The labeler for discrete scales is a closure over the discretized data.
            function labeler(i)
                if 0 < i <= length(levels(disc_data))
                    string(levels(disc_data)[int(i)])
                else
                    ""
                end
            end

            if contains(Set(names(aes)...), label_var)
                setfield(aes, label_var, labeler)
            end
        end
    end
end


type DiscreteColorScale <: Gadfly.ScaleElement
    f::Function # A function f(n) that produces a vector of n colors.
end


function element_aesthetics(scale::DiscreteColorScale)
    [:color]
end


# Common discrete color scales
const color_hue = DiscreteColorScale(
    h -> convert(Vector{ColorValue},
        distinguishable_colors(h, c -> deuteranopic(c, 0.8),
                               LCHab(70, 60, 240),
                               Float64[65, 70, 75, 80, 85],
                               Float64[0, 50, 60],
                               Float64[h for h in 0:30:360])))


function apply_scale(scale::DiscreteColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        if data.color === nothing
            continue
        end
        ds = discretize(data.color)
        colors = convert(Vector{ColorValue}, scale.f(length(levels(ds))))
        colorvals = Array(ColorValue, nonzero_length(ds.refs))
        i = 1
        for k in ds.refs
            if k != 0
                colorvals[i] = colors[k]
                i += 1
            end
        end

        colored_ds = PooledDataArray(colorvals, colors)
        aes.color = colored_ds

        color_map = {color => string(label)
                     for (label, color) in zip(levels(ds), colors)}
        aes.color_label = c -> color_map[c]
        aes.color_key_colors = colors
    end
end


type ContinuousColorScale <: Gadfly.ScaleElement
    # A function of the form f(p) where 0 <= p <= 1, that returns a color.
    f::Function
end


element_aesthetics(::ContinuousColorScale) = [:color]


# Common continuous color scales
# TODO: find a good color combo
const color_gradient = ContinuousColorScale(
        lab_gradient(LCHab(20, 44, 262), LCHab(100, 44, 262)))


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

    # It's a little weird to be doing this here. If a more elegant solution
    # arises, it's worth reorganizing.

    if cmin == Inf || cmax == -Inf
        return nothing
    end

    ticks = Gadfly.optimize_ticks(cmin, cmax)
    if ticks[1] == 0 && cmin >= 1
        ticks[1] = 1
    end

    cmin = ticks[1]
    cmax = ticks[end]
    cspan = cmax != cmin ? cmax - cmin : 1

    for (aes, data) in zip(aess, datas)
        if data.color === nothing
            continue
        end

        nas = [c === NA for c in data.color]
        cs = Array(ColorValue, length(data.color))
        for (i, c) in enumerate(data.color)
            if c === NA
                continue
            end
            cs[i] = scale.f((convert(Float64, c) - cmin) / cspan)
        end

        aes.color = PooledDataArray(cs, nas)

        color_labels = Dict{ColorValue, String}()
        for tick in ticks
            r = (tick - cmin) / cspan
            color_labels[scale.f(r)] = Gadfly.fmt_float(tick)
        end

        # Add a gradient of steps between labeled colors.
        num_steps = 1
        for (i, j) in zip(ticks, ticks[2:end])
            span = j - i
            for step in 1:num_steps
                k = i + span * (step / (1 + num_steps))
                r = (k - cmin) / cspan
                color_labels[scale.f(r)] = ""
            end
        end

        aes.color_label = c -> color_labels[c]
        aes.color_key_colors = [k for k in keys(color_labels)]
        sort!(aes.color_key_colors, order=Sort.Reverse)
        aes.color_key_continuous = true
    end
end


# Label scale is always discrete, hence we call it 'label' rather
# 'label_discrete'.
type LabelScale <: Gadfly.ScaleElement
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


element_aesthetics(::LabelScale) = [:scale]


const label = LabelScale()


end # module Scale

