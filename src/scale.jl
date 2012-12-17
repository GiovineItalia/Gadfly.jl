
module Scale

import Gadfly
import Gadfly.element_aesthetics

using DataFrames

load("Gadfly/src/color.jl")

# Apply some scales to data in the given order.
#
# Args:
#   scales: Zero or more scales
#   aess: Aesthetics (of the same length as datas) to update with scaled data.
#   datas: Zero or more data objects. (Yes, I know "datas" is not a real word.
#          Fuck English and it's stupid inconsistencies.)
#
# Returns:
#   nothing
#
function apply_scales(scales::Vector{Gadfly.ScaleElement},
                      aess::Vector{Gadfly.Aesthetics},
                      datas::Gadfly.Data...)
    for scale in scales
        apply_scale(scale, aess, datas...)
    end
end


# Apply some scales to data in the given order.
#
# Args:
#   scales: Zero or more scales
#   datas: Zero or more data objects.
#
# Returns:
#   A vector of Aesthetics of the same length as datas containing scaled data.
#
function apply_scales(scales::Vector{Gadfly.ScaleElement}, datas::Gadfly.Data...)
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
    var::Symbol
    trans::ContinuousScaleTransform
end


function scale_label(scale::ContinuousScale, x)
    scale.trans.label(x)
end


# Commonly used scales.
const x_continuous = ContinuousScale(:x, identity_transform)
const y_continuous = ContinuousScale(:y, identity_transform)
const x_log10      = ContinuousScale(:x, log10_transform)
const y_log10      = ContinuousScale(:y, log10_transform)
const x_log2       = ContinuousScale(:x, log2_transform)
const y_log2       = ContinuousScale(:y, log2_transform)
const x_log        = ContinuousScale(:x, ln_transform)
const y_log        = ContinuousScale(:y, ln_transform)
const x_asinh      = ContinuousScale(:x, asinh_transform)
const y_asinh      = ContinuousScale(:y, asinh_transform)
const x_sqrt       = ContinuousScale(:x, sqrt_transform)
const y_sqrt       = ContinuousScale(:y, sqrt_transform)


function element_aesthetics(scale::ContinuousScale)
    return [scale.var]
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
        if getfield(data, scale.var) === nothing
            continue
        end

        ds = Array(Float64, length(getfield(data, scale.var)))
        for (i, d) in enumerate(getfield(data, scale.var))
            ds[i] = scale.trans.f(convert(Float64, d))
        end

        setfield(aes, scale.var, ds)
    end
end




# Ok. Here is where I am stuck.
# If I make the color aesthetic an actual vector of colors, I need to hold on to
# the original values somehow in order to label elements. If I don't


discretize(values::Vector) = PooledDataVec(values)
discretize(values::DataVec) = PooledDataVec(values)
discretize(values::PooledDataVec) = values

type DiscreteScaleTransform
    f::Function
end


# Ok. So we'll have a transform that will convert discretized values to colors.
#


# A discrete scale maps data to sequential integers.
type DiscreteScale <: Gadfly.ScaleElement
    var::Symbol
    transform::DiscreteScaleTransform
end

# Ok, that's fine, but how do we assign colors for discrete color scales, or
# that something totally different?
#

type DiscreteColorScale <: Gadfly.ScaleElement
    f::Function # A function f(n) that produces a vector of n colors.
end


function element_aesthetics(scale::DiscreteColorScale)
    return [:color]
end


function scale_label(scale::DiscreteColorScale, c)
    # Ok, here we are. The decision I postponed until last. Here the scale
    # somehow has to know the mapping of colors to values in the data.
end


# Common discrete color scales
const color_hue = DiscreteColorScale(h -> lab_rainbow(70, 54, 0, h))


function apply_scale(scale::DiscreteColorScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)
    for (aes, data) in zip(aess, datas)
        if data.color === nothing
            continue
        end
        ds = discretize(data.color)
        colors = scale.f(length(levels(ds)))
        colored_ds = PooledDataVec(Color[colors[i] for i in ds.refs], colors)
        aes.color = colored_ds
        aes.color_key_colors = colors
        aes.color_key_labels = String[string(d) for d in levels(ds)]
    end
end


end # module Scale

