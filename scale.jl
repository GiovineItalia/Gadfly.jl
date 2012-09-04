# A scale is responsible for mapping data to attributes of a particular
# aesthetic. For example, mapping numerical data to a colors.


require("aesthetics.jl")
require("data.jl")

abstract Scale
typealias Scales Vector{Scale}

# Applying scales maps aesthetics
function apply_scales(scales::Scales, data::Vector{Data})
    aes = Aesthetics()

    for scale in scales
        ds = chain([getfield(d, a) for (a, d) in product(scale.aes, data)]...)
        aes = apply_scale(scale, ds, aes)
    end
end


# Catchall for unsupported types
function apply_scale{T <: Scale, S}(scale::T, v::S)
    error(@sprintf("Scale fo type %s is not applicable to data of type %s.",
                   string(T), string(S)))
end


type ContinuousScale <: Scale
    aes::Vector{Symbol}
    transform::Function
    min::Float64
    max::Float64
    ticks::Vector{Float64}

    function ContinuousScale(aes::Vector{Symbol}, transform::Function)
        new(aes, transform, 0.0, 0.0, Float64[])
    end
end


scale_x_continuous() = ContinuousScale([:x], identity)
scale_y_continuous() = ContinuousScale([:y], identity)
scale_x_log10()      = ContinuousScale([:x], log10)
scale_x_sqrt()       = ContinuousScale([:x], sqrt)
scale_x_asinh()      = ContinuousScale([:x], x::Float64 -> real(asinh(x + 0im)))


function train_scale(scale::ContinuousScale, v::Number)
    u = scale.transform(convert(Float64, v))
    if u < scale.min; scale.min = u; end
    if u > scale.max; scale.max = u; end
end


# Choose appealing places for tick marks from the min and max values.
function train_ticks(scale::ContinuousScale)

end


function apply_scale(scale::ContinuousScale, v::Number)
    # TODO: Handle INF and NA.
    scale.transform(convert(Float64, v))
end
