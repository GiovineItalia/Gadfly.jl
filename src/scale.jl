
module Scale

import Gadfly

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


# Continuous scale maps data on a continuous scale simple by calling
# `convert(Float64, ...)`.
type ContinuousScale <: Gadfly.ScaleElement
    vars::Vector{Symbol}
end


const x_continuous = ContinuousScale([:x])
const y_continuous = ContinuousScale([:y])


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
            if getfield(data, var) === nothing
                continue
            end

            ds = Array(Float64, length(getfield(data, var)))
            for (i, d) in enumerate(getfield(data, var))
                ds[i] = convert(Float64, d)
            end

            setfield(aes, var, ds)
        end
    end
end

end # module Scale

