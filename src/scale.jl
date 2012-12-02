
load("Gadfly/src/aesthetics.jl")
load("Gadfly/src/data.jl")

abstract Scale

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
function apply_scales(scales::Vector{Scale},
                      aess::Vector{Aesthetics},
                      datas::Data...)
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
function apply_scales(scales::Vector{Scale}, datas::Data...)
    aess = [Aesthetics() for _ in datas]
    apply_scales(scales, aess, datas...)
    aess
end


# Continuous scale maps data on a continuous scale simple by calling
# `convert(Float64, ...)`.
type ContinuousScale <: Scale
    vars::Vector{Symbol}
end


const scale_x_continuous = ContinuousScale([:x])
const scale_y_continuous = ContinuousScale([:y])


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
                     aess::Vector{Aesthetics}, datas::Data...)
    for (aes, data) in zip(aess, datas)
        for var in scale.vars
            if getfield(data, var) === nothing
                continue
            end

            ds = Array(Float64, length(getfield(data, var)))
            for (d, i) in enumerate(getfield(data, var))
                ds[i] = convert(Float64, d)
            end

            setfield(aes, var, ds)
        end
    end
end


