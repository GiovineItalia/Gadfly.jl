# A scale is responsible for mapping data to attributes of a particular
# aesthetic. For example, mapping numerical data to a colors.


require("aesthetics.jl")
require("data.jl")
require("iterators.jl")

import Iterators.*


abstract Scale
typealias Scales Vector{Scale}

abstract FittedScale
typealias FittedScales Vector{FittedScale}


# Scales work like so:
# A scale object is created which contains the information about how the scale
# shall be applied. This scale is then fit.

function fit_scales(scales::Scales, data::Data)
    fittedscales = Array(FittedScale, length(scales))

    for (scale, i) in enumerate(scales)
        ds = [getfield(data, var) for var in scale.vars]
        fittedscales[i] = fit_scale(scale, chain(filter(issomething, ds)...))
    end

    fittedscales
end


function apply_scales(scales::FittedScales, data::Data)
    aes = Aesthetics()
    for scale in scales
        for var in scale.spec.vars
            vs = getfield(data, var)
            if issomething(vs)
                setfield(aes, var, apply_scale(scale, vs))
            end
        end
    end

    aes
end


type ContinuousScale <: Scale
    vars::Vector{Symbol}
    trans::Function
end


# constructors for common scales
const scale_x_continuous = ContinuousScale([:x], identity)
const scale_y_continuous = ContinuousScale([:y], identity)

asinh(x::Float64) = real(asinh(x + 0im))

for (fun, coord) in product([log10, sqrt, asinh], ["x", "y"])
    scale_name = symbol(@sprintf("scale_%s_%s", coord, string(fun)))
    @eval begin
        const ($scale_name) = ContinuousScale([symbol(($coord))], ($fun))
    end
end


type FittedContinuousScale <: FittedScale
    spec::ContinuousScale
    min::Float64
    max::Float64
    ticks::Vector{Float64}

    function FittedContinuousScale(spec::ContinuousScale)
        new(spec, Inf, -Inf, Float64[])
    end
end


# Mabye this should set xlim/ylim in aes as well?
function fit_scale(scale::ContinuousScale, vs::Any)
    fittedscale = FittedContinuousScale(scale)
    for v in vs
        u = scale.trans(convert(Float64, v))
        if isfinite(u)
            if u < fittedscale.min
                fittedscale.min = u
            end

            if u > fittedscale.max
                fittedscale.max = u
            end
        end
    end

    if !isfinite(fittedscale.min)
        fittedscale.min = 0.0
    end

    if !isfinite(fittedscale.max)
        fittedscale.max = 1.0
    end

    # TODO: set ticks somehow

    fittedscale
end


function apply_scale(fittedscale::FittedContinuousScale, vs::Any)
    n = length(vs)
    us = Array(Float64, n)
    for (v, i) in enumerate(vs)
        us[i] = fittedscale.spec.trans(convert(Float64, v))
    end
    us
end




