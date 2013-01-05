
require("Distributions")

module Stat

require("Gadfly/src/bincount.jl")

import Distributions.Uniform

require("Iterators.jl")
import Iterators.chain, Iterators.cycle

import Gadfly
import Gadfly.Scale
using DataFrames

# Apply a series of statistics.
#
# Args:
#   stats: Statistics to apply in order.
#   aes: A Aesthetics instance.
#   trans: Map of variables to the transform applied to it.
#
# Returns:
#   Nothing, modifies aes.
#
function apply_statistics(stats::Vector{Gadfly.StatisticElement},
                          aes::Gadfly.Aesthetics)
    for stat in stats
        apply_statistic(stat, aes)
    end
    nothing
end

type Nil <: Gadfly.StatisticElement
end

const nil = Nil()

type Identity <: Gadfly.StatisticElement
end

function apply_statistic(stat::Identity, aes::Gadfly.Aesthetics)
    nothing
end

const identity = Identity()


type HistogramStatistic <: Gadfly.StatisticElement
end

const histogram = HistogramStatistic()


function apply_statistic(stat::HistogramStatistic, aes::Gadfly.Aesthetics)
    d, bincounts = choose_bin_count_1d(aes.x)

    x_min, x_max = min(aes.x), max(aes.x)
    binwidth = (x_max - x_min) / d

    aes.x_min = Array(Float64, d)
    aes.x_max = Array(Float64, d)
    aes.y = Array(Float64, d)

    for k in 1:d
        aes.x_min[k] = x_min + (k - 1) * binwidth
        aes.x_max[k] = x_min + k * binwidth
        aes.y[k] = bincounts[k]
    end

    nothing
end


# Find reasonable places to put tick marks and grid lines.
type TickStatistic <: Gadfly.StatisticElement
    in_vars::Vector{Symbol}
    out_var::Symbol
end


const x_ticks = TickStatistic([:x], :xtick)
const y_ticks = TickStatistic([:y], :ytick)


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
                while r*q*10^z <= x_min
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

    S = Array(Float64, int(k_best))
    for i in 0:(k_best - 1)
        S[i+1] = (r_best + i) * q_best * 10^z_best
    end

    S
end


# Apply a tick statistic.
#
# Args:
#   stat: statistic.
#   aes: aesthetics.
#
# Returns:
#   nothing
#
# Modifies:
#   aes
#
function apply_statistic(stat::TickStatistic, aes::Gadfly.Aesthetics)
    in_values = [getfield(aes, var) for var in stat.in_vars]
    in_values = filter(val -> !(val === nothing), in_values)
    in_values = chain(in_values...)

    minval = Inf
    maxval = -Inf
    all_int = true

    for val in in_values
        if val < minval
            minval = val
        end

        if val > maxval
            maxval = val
        end

        if !(typeof(val) <: Integer)
            all_int = false
        end
    end

    # all the input values in order.
    if all_int
        ticks = Set{Float64}()
        add_each(ticks, chain(in_values))
        ticks = Float64[t for t in ticks]
        sort!(ticks)
    else
        ticks = optimize_ticks(minval, maxval)
    end

    # We use the first label function we find for any of the aesthetics. I'm not
    # positive this is the right thing to do, or would would be.
    labeler = getfield(aes, symbol(@sprintf("%s_label", stat.in_vars[1])))

    setfield(aes, stat.out_var, ticks)
    setfield(aes, symbol(@sprintf("%s_label", stat.out_var)), labeler)

    nothing
end

type BoxplotStatistic <: Gadfly.StatisticElement
end

const boxplot = BoxplotStatistic()


function apply_statistic(stat::BoxplotStatistic, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("BoxplotStatistic", aes, :y)

    groups = Dict()

    aes_x = aes.x === nothing ? [nothing] : aes.x
    aes_color = aes.color === nothing ? [nothing] : aes.color

    for (x, y, c) in zip(cycle(aes_x), aes.y, cycle(aes_color))
        if !has(groups, (x, c))
            groups[(x, c)] = Float64[]
        else
            push(groups[(x, c)], y)
        end
    end

    m = length(groups)
    aes.middle = Array(Float64, m)
    aes.lower_hinge = Array(Float64, m)
    aes.upper_hinge = Array(Float64, m)
    aes.lower_fence = Array(Float64, m)
    aes.upper_fence = Array(Float64, m)
    aes.outliers = Vector{Float64}[]

    for (i, ((x, c), ys)) in enumerate(groups)
        aes.lower_hinge[i], aes.middle[i], aes.upper_hinge[i] =
                quantile(ys, [0.25, 0.5, 0.75])
        iqr = aes.upper_hinge[i] - aes.lower_hinge[i]
        aes.lower_fence[i] = aes.lower_hinge[i] - 1.5iqr
        aes.upper_fence[i] = aes.upper_hinge[i] + 1.5iqr
        push(aes.outliers,
             filter(y -> y < aes.lower_fence[i] || y > aes.upper_fence[i], ys))
    end

    if !is(aes.x, nothing)
        aes.x = Int64[x for (x, c) in keys(groups)]
    end

    if !is(aes.color, nothing)
        aes.color = PooledDataVector(Color[c for (x, c) in keys(groups)],
                                  levels(aes.color))
    end

    nothing
end


end # module Stat

