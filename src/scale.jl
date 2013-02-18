
module Scale

using Gadfly
using Compose
using DataFrames

import Gadfly.element_aesthetics

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

            ds = Array(Float64, length(getfield(data, var)))
            for (i, d) in enumerate(getfield(data, var))
                ds[i] = scale.trans.f(convert(Float64, d))
            end

            setfield(aes, var, ds)
            if has(Set(names(aes)...), label_var)
                setfield(aes, label_var, scale.trans.label)
            end
        end
    end
end


discretize(values::Vector) = PooledDataArray(values)
discretize(values::DataVector) = PooledDataArray(values)
discretize(values::PooledDataVector) = values

type DiscreteScaleTransform
    f::Function
end


type DiscreteScale <: Gadfly.ScaleElement
    var::Symbol
end


element_aesthetics(scale::DiscreteScale) = [scale.var]


const x_discrete = DiscreteScale(:x)
const y_discrete = DiscreteScale(:y)


function apply_scale(scale::DiscreteScale, aess::Vector{Gadfly.Aesthetics},
                     datas::Gadfly.Data...)
    label_var = symbol(@sprintf("%s_label", string(scale.var)))
    for (aes, data) in zip(aess, datas)
        if getfield(data, scale.var) === nothing
            continue
        end

        disc_data = discretize(getfield(data, scale.var))
        setfield(aes, scale.var, Int64[r for r in disc_data.refs])

        # The labeler for discrete scales is a closure over the discretized data.
        function labeler(i)
            if 0 < i <= length(levels(disc_data))
                string(levels(disc_data)[int(i)])
            else
                ""
            end
        end

        setfield(aes, label_var, labeler)
    end
end


type DiscreteColorScale <: Gadfly.ScaleElement
    f::Function # A function f(n) that produces a vector of n colors.
end


function element_aesthetics(scale::DiscreteColorScale)
    [:color]
end


# Common discrete color scales
#const color_hue = DiscreteColorScale(h -> Gadfly.lab_rainbow(70, 54, 0, h))
#const color_hue = DiscreteColorScale(h -> Color[deuteranopic(c) for c in Gadfly.lab_rainbow(70, 54, 0, h)])
#const color_hue = DiscreteColorScale(h -> Color[deuteranopic(c, 0.8) for c in Gadfly.lab_rainbow(70, 54, 0, h)])
#const color_hue = DiscreteColorScale(h -> distinguishable_colors(h, identity))
const color_hue = DiscreteColorScale(h -> distinguishable_colors(h, deuteranopic))


function apply_scale(scale::DiscreteColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        if data.color === nothing
            continue
        end
        ds = discretize(data.color)
        colors = scale.f(length(levels(ds)))
        colored_ds = PooledDataArray(Color[colors[i] for i in ds.refs], colors)
        aes.color = colored_ds

        color_map = {color => label for (label, color) in zip(levels(ds), colors)}
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

    for (aes, data) in zip(aess, datas)
        if data.color === nothing
            continue
        end

        nas = [c === NA for c in data.color]
        cs = Array(Color, length(data.color))
        for (i, c) in enumerate(data.color)
            if c === NA
                continue
            end
            cs[i] = scale.f((convert(Float64, c) - cmin) / (cmax - cmin))
        end

        aes.color = DataArray(cs, nas)

        color_labels = Dict{Color, String}()
        for tick in ticks
            r = (tick - cmin) / (cmax - cmin)
            color_labels[scale.f(r)] = Gadfly.fmt_float(tick)
        end

        # Add a gradient of steps between labeled colors.
        num_steps = 1
        for (i, j) in zip(ticks, ticks[2:end])
            span = j - i
            for step in 1:num_steps
                k = i + span * (step / (1 + num_steps))
                r = (k - cmin) / (cmax - cmin)
                color_labels[scale.f(r)] = ""
            end
        end

        aes.color_label = c -> color_labels[c]
        aes.color_key_colors = reverse(sort(keys(color_labels)))
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

