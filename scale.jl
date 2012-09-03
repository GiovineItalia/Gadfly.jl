# A scale is responsible for mapping data to attributes of a particular
# aesthetic. For example, mapping numerical data to a colors.


require("aesthetics.jl")
require("data.jl")

abstract Scale
typealias Scales Vector{Scale}

# Training modifies the scale. What happens if a plot is created, rendered,
# modified then rendered again? Will this cause problems?


# Before applying a scale, it is trained, which gives it an opportunity to set
# the range of the data, etc.
function train_scales(scales::Scales, data::Data)
    for scale in scales
        for a in scale.aes
            vs = getfield(data, a)
            if typeof(vs) != Nothing
                for v in vs
                    train_scale(scale, v)
                end
            end
        end
    end
end


# Applying scales maps aesthetics
function apply_scales(scales::Scales, data::Data)
    aes = Aesthetics()
    for scale in scales
        for a in scale.aes
            vs = getfield(data, a)
            if typeof(vs) != Nothing
                us = Array(Float64, length(vs))
                for (v, i) in enumerate(vs)
                    us[i] = apply_scale(scale, v)
                end
                setfield(aes, a, us)
            end
        end
    end
    aes
end


# Catchall for unsupported types
function train_scale{T <: Scale, S}(scale::T, v::S)
    error(@sprintf("Scale fo type %s is not applicable to data of type %s.",
                   string(T), string(S)))
end


function apply_scale{T <: Scale, S}(scale::T, v::S)
    error(@sprintf("Scale fo type %s is not applicable to data of type %s.",
                   string(T), string(S)))
end


type ContinuousScale <: Scale
    aes::Vector{Symbol}
    transform::Function
    min::Float64
    max::Float64

    function ContinuousScale(aes::Vector{Symbol}, transform::Function)
        new(aes, transform, 0.0, 0.0)
    end
end


scale_x_continuous() = ContinuousScale([:x], identity)
scale_y_continuous() = ContinuousScale([:y], identity)
scale_x_log10()      = ContinuousScale([:x], log10)
scale_x_sqrt()       = ContinuousScale([:x], sqrt)
scale_x_asinh()      = ContinuousScale([:x], x::Float64 -> real(asinh(x + 0im)))


# TODO: Handle INF and NA.

function train_scale(scale::ContinuousScale, v::Number)
    u = scale.transform(convert(Float64, v))
    if u < scale.min; scale.min = u; end
    if u > scale.max; scale.max = u; end
end


function apply_scale(scale::ContinuousScale, v::Number)
    u = scale.transform(convert(Float64, v))
    if scale.min == scale.max
        0.5
    else
        (u - scale.min) / (scale.max - scale.min)
    end
end


type DiscreteScale <: Scale
    aes::Vector{Symbol}
    values::Set{Any}

    # Values or sorted lazily (i.e., when needed) to get a reasonable order.
    value_order_dirty::Bool
    value_order::Dict{Any, Int}

    function DiscreteScale(aes::Vector{Symbol})
        new(aes, Set(), false, Dict{Any, Int}())
    end
end


function train_scale(scale::DiscreteScale, v::Any)
    for x in xs
        add(scale.values, x)
    end
    scale.value_order_dirtly = true
end


function apply_scale{T}(scale::ContinuousScale, v::Any)
    if scale.value_order_dirty
        ordered_values = sort([u for u in scale.values])
        for (i, u) in enumerate(ordered_values)
            scale.value_order[u] = i
        end
    end

    (scale.value_order[v] - 1) / length(scale.values)
end


