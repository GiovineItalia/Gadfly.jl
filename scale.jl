# A scale is responsible for mapping data to attributes of a particular
# aesthetic. For example, mapping numerical data to a colors.

require("aesthetics.jl")
require("data.jl")
require("iterators.jl")
require("transform.jl")

import Iterators.*

# A note on how scales work in gadfly;
# Scales have a few functions: map data to a coordinate system, produce a
# reasonable set of tick marks, and label values. So, for example a discrete
# scale over values ["a", "b", "c"] must map these categorial values to real
# values [1, 2, 3] which can actually be plotted. It must also properly
# identify these points and label them "a", "b", "c", since the steps performed
# after applying scales are ignorant of the orignal data.


abstract Scale
typealias Scales Vector{Scale}

abstract FittedScale
typealias FittedScales Vector{FittedScale}


# Fit a set of scales to data.
#
# Args:
#   scales: Specifications of scales to fit.
#
# Returns:
#   A vector of fitted scales.
#
function fit_scales(scales::Scales, data::Data)
    fittedscales = Array(FittedScale, length(scales))

    for (scale, i) in enumerate(scales)
        ds = [getfield(data, var) for var in scale.vars]
        fittedscales[i] = fit_scale(scale, chain(filter(issomething, ds)...))
    end

    fittedscales
end


# Apply scales to data.
#
# Args:
#   fittedscales: Scales that have been previously fit to data.
#
# Returns:
#   An instance of aesthetics containing mapped data.
#
function apply_scales(scales::FittedScales, data::Data)
    aes = Aesthetics()
    for scale in scales
        update!(aes, apply_scale(scale, data))
    end
    aes
end


# A continuous scale which maps continuous data to continuous data, with or
# without some transform and heuristically produces some reasonable tick marks.
type ContinuousScale <: Scale
    vars::Vector{Symbol}
    tick_var::Symbol
    trans::Transform
end


# Prototypical scales.
const scale_x_continuous = ContinuousScale([:x], :xticks, IdenityTransform)
const scale_y_continuous = ContinuousScale([:y], :yticks, IdenityTransform)



for ((name, t), coord) in product(preset_transforms, ["x", "y"])
    tick_var = @sprintf("%sticks", coord)
    scale_name = symbol(@sprintf("scale_%s_%s", coord, name))
    @eval begin
        const $scale_name = ContinuousScale([symbol($coord)],
                                            symbol($tick_var), $t)
    end
end


# A continuous scale that has been fit to the data.
type FittedContinuousScale <: FittedScale
    spec::ContinuousScale
    min::Float64
    max::Float64

    function FittedContinuousScale(spec::ContinuousScale)
        new(spec, Inf, -Inf)
    end
end


# Fit a continuous scale.
#
# Fitting in this case is just finding the minimum and maximum values.
#
# Args:
#   scale: A continuous scale to fit.
#   vs: Data to fit to in the form of an iterator producing something that may
#       be converted to Float64
#
function fit_scale(scale::ContinuousScale, vs::Any)
    fittedscale = FittedContinuousScale(scale)
    for v in vs
        u = scale.trans.f(convert(Float64, v))
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

    fittedscale
end


# Find some reasonable values for tick marks.
#
# This is basically Wilkinson's ad-hoc scoring method that tries to balance
# tight fit around the data, optimal number of ticks, and simple numbers.
#
# Args:
#   x_min: minimum value occuring in the data.
#   x_max: maximum value occuring in the data.
#
# Returns:
#   A Float64 vector containing tick marks.
#
function optimize_ticks(x_min::Float64, x_max::Float64)
    # TODO: these should perhaps be part of the theme
    const Q = {(1,1), (5, 0.9), (2, 0.7), (25, 0.5), (3, 0.2)}
    const n = length(Q)
    const k_min   = 2
    const k_max   = 10
    const k_ideal = 5

    xspan = x_max - x_min
    z = ceil(log10(xspan))

    high_score = -Inf
    z_best = 0.0
    k_best = 0.0
    r_best = 0.0
    q_best = 0.0

    while k_max * 10^(z+1) > xspan
        for k in k_min:k_max
            for (q, qscore) in Q
                span = (k - 1) * q * 10^z
                if span < xspan
                    continue
                end

                r = ceil((x_max - span) / (q*10^z))
                while r*q*10^z < x_min
                    has_zero = r <= 0 && abs(r) < k

                    # simplicity
                    s = has_zero ? 1.0 : 0.0

                    # granularity
                    g = 0 < k < 2k_ideal ? 1 - abs(k - k_ideal) / k_ideal : 0.0

                    # coverage
                    c = xspan/span

                    score = (1/4)g + (1/6)s + (1/3)c + (1/4)qscore

                    if score > high_score
                        (q_best, r_best, k_best, z_best) = (q, r, k, z)
                        high_score = score
                    end
                    r += 1
                end
            end
        end
        z -= 1
    end

    S = [(r_best + i) * q_best * 10^z_best for i in 0:(k_best - 1)]
end


# Apply a a fitted scale to data, producing aesthetics.
#
# Args:
#   fittedscale: a fitted continuous scale
#   data: data to apply the scale to
#
# Returns:
#   An instance of Aesthetics with mapped data.
#
function apply_scale(fittedscale::FittedContinuousScale, data::Data)
    aes = Aesthetics()
    tick_var = fittedscale.spec.tick_var

    if issomething(getfield(data, tick_var))
        # TODO: handle custom ticks.
    else
        S = optimize_ticks(fittedscale.min, fittedscale.max)
        ticks = Dict{Float64, String}()
        for s in S
            ticks[s] = fittedscale.spec.trans.label(s)
        end

        setfield(aes, tick_var, ticks)
    end

    for var in fittedscale.spec.vars
        vs = getfield(data, var)
        if issomething(vs)
            setfield(aes, var, apply_scale(fittedscale, vs))
        end
    end
    aes
end


# Apply a fitted continous scale to one particular piece of data.
#
# Args:
#   fittedscale: a fitted continuous scale.
#   vs: an iterator producing value that can be converted to Float64
#
# Returns:
#   A Float64 vector.
#
function apply_scale(fittedscale::FittedContinuousScale, vs::Any)
    n = length(vs)
    us = Array(Float64, n)
    for (v, i) in enumerate(vs)
        us[i] = fittedscale.spec.trans.f(convert(Float64, v))
    end
    us
end


