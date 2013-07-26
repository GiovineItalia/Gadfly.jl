
module Stat

import Gadfly
using DataFrames
using Compose
using Color

import Gadfly.Scale, Gadfly.Coord, Gadfly.element_aesthetics,
       Gadfly.default_scales, Gadfly.isconcrete, Gadfly.nonzero_length
import Distributions.Uniform, Distributions.kde
import Iterators.chain, Iterators.cycle, Iterators.product, Iterators.partition

include("bincount.jl")

# Apply a series of statistics.
#
# Args:
#   stats: Statistics to apply in order.
#   scales: Scales used by the plot.
#   aes: A Aesthetics instance.
#
# Returns:
#   Nothing, modifies aes.
#
function apply_statistics(stats::Vector{Gadfly.StatisticElement},
                          scales::Dict{Symbol, Gadfly.ScaleElement},
                          coord::Gadfly.CoordinateElement,
                          aes::Gadfly.Aesthetics)
    for stat in stats
        apply_statistic(stat, scales, coord, aes)
    end
    nothing
end

type Nil <: Gadfly.StatisticElement
end

const nil = Nil()

type Identity <: Gadfly.StatisticElement
end

function apply_statistic(stat::Identity,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    nothing
end

const identity = Identity()


type HistogramStatistic <: Gadfly.StatisticElement
end


element_aesthetics(::HistogramStatistic) = [:x]


const histogram = HistogramStatistic()


function apply_statistic(stat::HistogramStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("HistogramStatistic", aes, :x)
    d, bincounts = choose_bin_count_1d(aes.x)

    x_min, x_max = min(aes.x), max(aes.x)
    binwidth = (x_max - x_min) / d

    if aes.color === nothing
        aes.x_min = Array(Float64, d)
        aes.x_max = Array(Float64, d)
        aes.y = Array(Float64, d)

        for j in 1:d
            aes.x_min[j] = x_min + (j - 1) * binwidth
            aes.x_max[j] = x_min + j * binwidth
            aes.y[j] = bincounts[j]
        end
    else
        groups = Dict()
        for (x, c) in zip(aes.x, cycle(aes.color))
            if !haskey(groups, c)
                groups[c] = Float64[x]
            else
                push!(groups[c], x)
            end
        end

        aes.x_min = Array(Float64, d * length(groups))
        aes.x_max = Array(Float64, d * length(groups))
        aes.y = Array(Float64, d * length(groups))
        colors = Array(ColorValue, d * length(groups))

        x_min = min(aes.x)
        x_max = max(aes.x)
        stack_height = zeros(Int, d)
        for (i, (c, xs)) in enumerate(groups)
            fill!(bincounts, 0)
            for x in xs
                bin = max(1, min(d, int(ceil((x - x_min) / binwidth))))
                bincounts[bin] += 1
            end
            stack_height += bincounts[1:d]

            for j in 1:d
                idx = (i-1)*d + j
                aes.x_min[idx] = x_min + (j - 1) * binwidth
                aes.x_max[idx] = x_min + j * binwidth
                aes.y[idx] = bincounts[j]
                colors[idx] = c
            end
        end

        y_drawmax = float64(max(stack_height))
        if aes.y_drawmax === nothing || aes.y_drawmax < y_drawmax
            aes.y_drawmax = y_drawmax
        end

        aes.color = PooledDataArray(colors)
    end
end


type DensityStatistic <: Gadfly.StatisticElement
    # Number of points sampled
    n::Int
end


const density = DensityStatistic(300)


element_aesthetics(::DensityStatistic) = [:x, :y]


function apply_statistic(stat::DensityStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("DensityStatistic", aes, :x)

    # TODO: handle grouping by color

    f = kde(aes.x, stat.n)
    aes.x = f.x
    aes.y = f.density
end



type RectangularBinStatistic <: Gadfly.StatisticElement
end


element_aesthetics(::RectangularBinStatistic) = [:x, :y, :color]


default_scales(::RectangularBinStatistic) = [Gadfly.Scale.color_gradient]


const rectbin = RectangularBinStatistic()


function apply_statistic(stat::RectangularBinStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    dx, dy, bincounts = choose_bin_count_2d(aes.x, aes.y)

    x_min, x_max = min(aes.x), max(aes.x)
    y_min, y_max = min(aes.y), max(aes.y)

    # bin widths
    wx = (x_max - x_min) / dx
    wy = (y_max - y_min) / dy

    n = 0
    for cnt in bincounts
        if cnt > 0
            n += 1
        end
    end

    aes.x_min = Array(Float64, n)
    aes.x_max = Array(Float64, n)
    aes.y_min = Array(Float64, n)
    aes.y_max = Array(Float64, n)

    k = 1
    for ((i, j), cnt) in zip(product(1:dy, 1:dx), bincounts)
        if cnt > 0
            aes.x_min[k] = x_min + (i - 1) * wx
            aes.x_max[k] = x_min + i * wx
            aes.y_min[k] = y_min + (j - 1) * wy
            aes.y_max[k] = y_min + j * wy
            k += 1
        end
    end

    if !has(scales, :color)
        error("RectangularBinStatistic requires a color scale.")
    end
    color_scale = scales[:color]
    if !(typeof(color_scale) <: Scale.ContinuousColorScale)
        error("RectangularBinStatistic requires a continuous color scale.")
    end

    aes.color_key_title = "Count"

    data = Gadfly.Data()
    data.color = Array(Int, n)
    k = 1
    for cnt in bincounts
        if cnt > 0
            data.color[k] = cnt
            k += 1
        end
    end
    Scale.apply_scale(color_scale, [aes], data)
    nothing
end


default_statistic(stat::RectangularBinStatistic) = [Scale.color_gradient]


# Find reasonable places to put tick marks and grid lines.
type TickStatistic <: Gadfly.StatisticElement
    in_vars::Vector{Symbol}
    out_var::String
end


const x_ticks = TickStatistic([:x, :x_min, :x_max, :x_drawmin, :x_drawmax], "x")
const y_ticks = TickStatistic(
    [:y, :y_min, :y_max, :middle, :lower_hinge, :upper_hinge,
     :lower_fence, :upper_fence, :y_drawmin, :y_drawmax], "y")


# Can a numerical value be treated as an integer
is_int_compatable(::Integer) = true
is_int_compatable{T <: FloatingPoint}(x::T) = abs(x) < maxintfloat(T) && float(int(x)) == x
is_int_compatable(::Any) = false

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
function apply_statistic(stat::TickStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    in_values = [getfield(aes, var) for var in stat.in_vars]
    in_values = filter(val -> !(val === nothing), in_values)
    in_values = chain(in_values...)
    # TODO: handle the outliers aesthetic

    minval = Inf
    maxval = -Inf
    all_int = true

    n = 0
    for val in in_values
        if val < minval
            minval = float64(val)
        end

        if val > maxval
            maxval = float64(val)
        end

        if !is_int_compatable(val)
            all_int = false
        end

        n += 1
    end

    # Take into account a forced viewport in cartesian coordinates.
    if typeof(coord) == Coord.Cartesian
        if stat.out_var == "x"
            if !is(coord.xmin, nothing)
                minval == min(minval, float64(coord.xmin))
            end
            if !is(coord.xmax, nothing)
                maxval == max(maxval, float64(coord.xmax))
            end
        elseif stat.out_var == "y"
            if !is(coord.ymin, nothing)
                minval == min(minval, float64(coord.ymin))
            end
            if !is(coord.ymax, nothing)
                maxval == min(maxval, float64(coord.ymax))
            end
        end
    end

    # all the input values in order.
    if all_int
        ticks = Set{Float64}()
        union!(ticks, in_values)
        ticks = Float64[t for t in ticks]
        sort!(ticks)

        maxgap = 0
        for (i, j) in partition(ticks, 2, 1)
            if j - i > maxgap
                maxgap = j -i
            end
        end

        if length(ticks) > 20 || maxgap > 1
            grids = ticks = Gadfly.optimize_ticks(minval, maxval)
            if ticks[1] == 0
                ticks[1] = 1
            end
            grids = ticks
        else
            grids = (ticks - 0.5)[2:end]
        end
        viewmin = min(ticks)
        viewmax = max(ticks)
    else
        ticks = Gadfly.optimize_ticks(minval, maxval)
        viewmin = min(ticks)
        viewmax = max(ticks)

        # Extend ticks
        d = ticks[2] - ticks[1]
        lowerticks = ticks - (ticks[end] - ticks[1]) - d
        upperticks = ticks + (ticks[end] - ticks[1]) + d
        grids = ticks = vcat(lowerticks, ticks, upperticks)
    end

    # We use the first label function we find for any of the aesthetics. I'm not
    # positive this is the right thing to do, or would would be.
    labeler = getfield(aes, symbol(string(stat.out_var, "_label")))

    setfield(aes, symbol(string(stat.out_var, "tick")), ticks)
    setfield(aes, symbol(string(stat.out_var, "grid")), grids)
    setfield(aes, symbol(string(stat.out_var, "tick_label")), labeler)

    viewmin_var = symbol(string(stat.out_var, "_viewmin"))
    if getfield(aes, viewmin_var) === nothing ||
       getfield(aes, viewmin_var) > viewmin
        setfield(aes, viewmin_var, viewmin)
    end

    viewmax_var = symbol(string(stat.out_var, "_viewmax"))
    if getfield(aes, viewmax_var) === nothing ||
       getfield(aes, viewmax_var) < viewmax
        setfield(aes, viewmax_var, viewmax)
    end

    nothing
end

type BoxplotStatistic <: Gadfly.StatisticElement
end


element_aesthetics(::BoxplotStatistic) = [:x, :y]


const boxplot = BoxplotStatistic()


function apply_statistic(stat::BoxplotStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("BoxplotStatistic", aes, :y)

    groups = Dict()

    aes_x = aes.x === nothing ? [nothing] : aes.x
    aes_color = aes.color === nothing ? [nothing] : aes.color

    for (x, y, c) in zip(cycle(aes_x), aes.y, cycle(aes_color))
        if !haskey(groups, (x, c))
            groups[(x, c)] = Float64[y]
        else
            push!(groups[(x, c)], y)
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
        push!(aes.outliers,
             filter(y -> y < aes.lower_fence[i] || y > aes.upper_fence[i], ys))
    end

    if !is(aes.x, nothing)
        aes.x = Int64[x for (x, c) in keys(groups)]
    end

    if !is(aes.color, nothing)
        aes.color = PooledDataArray(ColorValue[c for (x, c) in keys(groups)],
                                    levels(aes.color))
    end

    nothing
end


end # module Stat

