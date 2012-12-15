
module Scale

import Gadfly
import Gadfly.element_aesthetics

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
    ContinuousScaleTransform(sqrt, x -> x^2, x -> Gadfly.fmt_float(sqrt(x)))


# Continuous scale maps data on a continuous scale simple by calling
# `convert(Float64, ...)`.
type ContinuousScale <: Gadfly.ScaleElement
    var::Symbol
    trans::ContinuousScaleTransform
end


function scale_label(scale::ContinuousScale, x)
    scale.trans.label(x)
end


const x_continuous = ContinuousScale(:x, identity_transform)
const y_continuous = ContinuousScale(:y, identity_transform)


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



# How will labels work with discrete scales?
#
# The system now works like:
# 1. Scales are applied.
# 2. Transforms are applied.
#
# If we convert data to colors in step 1, how to we know

#
# Let's make the aesthetic types for color be a PooledDataVec.
# Maybe we can avoid having a f-inverse for transforms then.
#

function discretize()

end


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


const color_hue = DiscreteColorScale(h -> lab_rainbow(70, 54, 0, h))


function apply_scale(scale::DiscreteScale,
                     aess::Vector{Gadfly.Aesthetics}, datas::Gadfly.Data...)

end

end # module Scale

