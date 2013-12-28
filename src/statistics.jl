module Stat

import Gadfly
using DataArrays
using Compose
using Color
using Loess

import Gadfly.Scale, Gadfly.Coord, Gadfly.element_aesthetics,
       Gadfly.default_scales, Gadfly.isconcrete, Gadfly.nonzero_length
import Distributions.Uniform, Distributions.kde, Distributions.bandwidth
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

immutable Nil <: Gadfly.StatisticElement
end

const nil = Nil

immutable Identity <: Gadfly.StatisticElement
end

function apply_statistic(stat::Identity,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    nothing
end

const identity = Identity


immutable HistogramStatistic <: Gadfly.StatisticElement
    minbincount::Int
    maxbincount::Int

    function HistogramStatistic(; bincount=nothing,
                                  minbincount=3,
                                  maxbincount=150)
        if bincount != nothing
            new(bincount, bincount)
        else
            new(minbincount, maxbincount)
        end
    end
end


element_aesthetics(::HistogramStatistic) = [:x]


const histogram = HistogramStatistic


function apply_statistic(stat::HistogramStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("HistogramStatistic", aes, :x)

    if stat.minbincount > stat.maxbincount
        error("Histogram minbincount > maxbincount")
    end

    if isempty(aes.x)
        aes.xmin = Float64[1.0]
        aes.xmax = Float64[1.0]
        aes.y = Float64[0.0]
        return
    end

    if haskey(scales, :x) && isa(scales[:x], Scale.DiscreteScale)
        x_min = minimum(aes.x)
        x_max = maximum(aes.x)
        d = x_max - x_min + 1
        bincounts = zeros(Int, d)
        for x in aes.x
            bincounts[x - x_min + 1] += 1
        end
    else
        d, bincounts = choose_bin_count_1d(aes.x,
                                           stat.minbincount,
                                           stat.maxbincount)
    end

    x_min, x_max = Gadfly.concrete_minimum(aes.x), Gadfly.concrete_maximum(aes.x)
    binwidth = (x_max - x_min) / d

    if aes.color === nothing
        aes.xmin = Array(Float64, d)
        aes.xmax = Array(Float64, d)
        aes.y = Array(Float64, d)

        for j in 1:d
            aes.xmin[j] = x_min + (j - 1) * binwidth
            aes.xmax[j] = x_min + j * binwidth
            aes.y[j] = bincounts[j]
        end
    else
        groups = Dict()
        for (x, c) in zip(aes.x, cycle(aes.color))
            if !Gadfly.isconcrete(x)
                continue
            end

            if !haskey(groups, c)
                groups[c] = Float64[x]
            else
                push!(groups[c], x)
            end
        end

        aes.xmin = Array(Float64, d * length(groups))
        aes.xmax = Array(Float64, d * length(groups))
        aes.y = Array(Float64, d * length(groups))
        colors = Array(ColorValue, d * length(groups))

        x_min = Gadfly.concrete_minimum(aes.x)
        x_max = Gadfly.concrete_maximum(aes.x)
        stack_height = zeros(Int, d)
        for (i, (c, xs)) in enumerate(groups)
            fill!(bincounts, 0)
            for x in xs
                if !Gadfly.isconcrete(x)
                    continue
                end
                bin = max(1, min(d, int(ceil((x - x_min) / binwidth))))
                bincounts[bin] += 1
            end
            stack_height += bincounts[1:d]

            for j in 1:d
                idx = (i-1)*d + j
                aes.xmin[idx] = x_min + (j - 1) * binwidth
                aes.xmax[idx] = x_min + j * binwidth
                aes.y[idx] = bincounts[j]
                colors[idx] = c
            end
        end

        y_drawmax = float64(maximum(stack_height))
        if aes.ydrawmax === nothing || aes.ydrawmax < y_drawmax
            aes.ydrawmax = y_drawmax
        end

        aes.color = PooledDataArray(colors)
    end

    aes.y_label = Scale.identity_formatter
end


immutable DensityStatistic <: Gadfly.StatisticElement
    # Number of points sampled
    n::Int

    function DensityStatistic(n=300)
        new(n)
    end
end


const density = DensityStatistic


element_aesthetics(::DensityStatistic) = [:x, :y]


function apply_statistic(stat::DensityStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("DensityStatistic", aes, :x)

    if aes.color === nothing
        if !isa(aes.x[1], Real)
            error("Kernel density estimation only works on Real types.")
        end

        x_f64 = convert(Vector{Float64}, aes.x)
        # When will stat.n ever be <= 1? Seems pointless
        # certainly its length will always be 1
        window = stat.n > 1 ? bandwidth(x_f64) : 0.1
        f = kde(x_f64, window, stat.n)
        aes.x = f.x
        aes.y = f.density
    else
        groups = Dict()
        for (x, c) in zip(aes.x, cycle(aes.color))
            if !haskey(groups, c)
                groups[c] = Float64[x]
            else
                push!(groups[c], x)
            end
        end

        colors = Array(ColorValue, 0)
        aes.x = Array(Float64, 0)
        aes.y = Array(Float64, 0)
        for (c, xs) in groups
            window = stat.n > 1 ? bandwidth(xs) : 0.1
            f = kde(xs, window, stat.n)
            append!(aes.x, f.x)
            append!(aes.y, f.density)
            for _ in 1:length(f.x)
                push!(colors, c)
            end
        end
        aes.color = PooledDataArray(colors)
    end
    aes.y_label = Gadfly.Scale.identity_formatter
end



immutable Histogram2DStatistic <: Gadfly.StatisticElement
    xminbincount::Int
    xmaxbincount::Int
    yminbincount::Int
    ymaxbincount::Int

    function Histogram2DStatistic(; xbincount=nothing,
                                    xminbincount=3,
                                    xmaxbincount=150,
                                    ybincount=nothing,
                                    yminbincount=3,
                                    ymaxbincount=150)
        if xbincount != nothing
            xminbincount = xbincount
            xmaxbincount = xbincount
        end

        if ybincount != nothing
            yminbincount = ybincount
            ymaxbincount = ybincount
        end

        new(xminbincount, xmaxbincount, yminbincount, ymaxbincount)
    end
end


element_aesthetics(::Histogram2DStatistic) = [:x, :y, :color]


default_scales(::Histogram2DStatistic) = [Gadfly.Scale.continuous_color()]


const histogram2d = Histogram2DStatistic


function apply_statistic(stat::Histogram2DStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Histogram2DStatistic", aes, :x, :y)

    x_min, x_max = Gadfly.concrete_minimum(aes.x), Gadfly.concrete_maximum(aes.x)
    y_min, y_max = Gadfly.concrete_minimum(aes.y), Gadfly.concrete_maximum(aes.y)

    if haskey(scales, :x) && isa(scales[:x], Scale.DiscreteScale)
        x_categorial = true
        xminbincount = x_max - x_min + 1
        xmaxbincount = xminbincount
    else
        x_categorial = false
        xminbincount = stat.xminbincount
        xmaxbincount = stat.xmaxbincount
    end

    if haskey(scales, :y) && isa(scales[:y], Scale.DiscreteScale)
        y_categorial = true
        yminbincount = y_max - y_min + 1
        ymaxbincount = yminbincount
    else
        y_categorial = false
        yminbincount = stat.yminbincount
        ymaxbincount = stat.ymaxbincount
    end

    dy, dx, bincounts = choose_bin_count_2d(aes.x, aes.y,
                                            xminbincount, xmaxbincount,
                                            yminbincount, ymaxbincount)

    wx = x_categorial ? 1 : (x_max - x_min) / dx
    wy = y_categorial ? 1 : (y_max - y_min) / dx

    n = 0
    for cnt in bincounts
        if cnt > 0
            n += 1
        end
    end

    if x_categorial
        aes.x = Array(Int64, n)
    else
        aes.xmin = Array(Float64, n)
        aes.xmax = Array(Float64, n)
    end

    if y_categorial
        aes.y = Array(Int64, n)
    else
        aes.ymin = Array(Float64, n)
        aes.ymax = Array(Float64, n)
    end

    k = 1
    for i in 1:dy, j in 1:dx
        cnt = bincounts[i, j]
        if cnt > 0
            if x_categorial
                aes.x[k] = x_min + (j - 1)
            else
                aes.xmin[k] = x_min + (j - 1) * wx
                aes.xmax[k] = x_min + j * wx
            end

            if y_categorial
                aes.y[k] = y_min + (i - 1)
            else
                aes.ymin[k] = y_min + (i - 1) * wy
                aes.ymax[k] = y_min + i * wy
            end
            k += 1
        end
    end
    @assert k - 1 == n

    if !haskey(scales, :color)
        error("Histogram2DStatistic requires a color scale.")
    end
    color_scale = scales[:color]
    if !(typeof(color_scale) <: Scale.ContinuousColorScale)
        error("Histogram2DStatistic requires a continuous color scale.")
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

    if x_categorial
        aes.x = PooledDataArray(aes.x)
    end

    if y_categorial
        aes.y = PooledDataArray(aes.y)
    end

    Scale.apply_scale(color_scale, [aes], data)
    nothing
end


# Find reasonable places to put tick marks and grid lines.
immutable TickStatistic <: Gadfly.StatisticElement
    in_vars::Vector{Symbol}
    out_var::String
end


const xticks = TickStatistic([:x, :xmin, :xmax, :xdrawmin, :xdrawmax], "x")
const yticks = TickStatistic(
    [:y, :ymin, :ymax, :middle, :lower_hinge, :upper_hinge,
     :lower_fence, :upper_fence, :ydrawmin, :ydrawmax], "y")


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
    in_group_var = symbol(string(stat.out_var, "group"))
    if getfield(aes, in_group_var) === nothing
        in_values = [getfield(aes, var) for var in stat.in_vars]
        in_values = filter(val -> !(val === nothing), in_values)
        if isempty(in_values)
            return
        end
        in_values = chain(in_values...)
        categorical = all([getfield(aes, var) === nothing || typeof(getfield(aes, var)) <: PooledDataArray
                           for var in stat.in_vars])
    else
        in_values = getfield(aes, in_group_var)
        categorical = true
    end

    # TODO: handle the outliers aesthetic

    minval = Gadfly.concrete_minimum(in_values)
    maxval = Gadfly.concrete_maximum(in_values)
    n = Gadfly.concrete_length(in_values)

    # take into account a forced viewport in cartesian coordinates.
    if typeof(coord) == Coord.Cartesian
        if stat.out_var == "x"
            if !is(coord.xmin, nothing)
                minval = min(minval, coord.xmin)
            end
            if !is(coord.xmax, nothing)
                maxval = max(maxval, coord.xmax)
            end
        elseif stat.out_var == "y"
            if !is(coord.ymin, nothing)
                minval = min(minval, coord.ymin)
            end
            if !is(coord.ymax, nothing)
                maxval = max(maxval, coord.ymax)
            end
        end
    end

    # check the x/yviewmin/max pesudo-aesthetics
    if stat.out_var == "x"
        if aes.xviewmin != nothing
            minval = aes.xviewmin
        end
        if aes.xviewmax != nothing
            maxval = aes.xviewmax
        end
    elseif stat.out_var == "y"
        if aes.yviewmin != nothing
            minval = aes.yviewmin
        end
        if aes.yviewmax != nothing
            maxval = aes.yviewmax
        end
    end

    # all the input values in order.
    if categorical
        ticks = Set()
        for in_value in in_values
            push!(ticks, in_value)
        end
        ticks = Float64[t for t in ticks]
        sort!(ticks)

        maxgap = 0
        for (i, j) in partition(ticks, 2, 1)
            if j - i > maxgap
                maxgap = j -i
            end
        end

        if length(ticks) > 20 || maxgap > 1
            ticks, viewmin, viewmax = Gadfly.optimize_ticks(minval, maxval)
            if ticks[1] == 0
                ticks[1] = 1
            end
            grids = ticks
        else
            grids = (ticks - 0.5)[2:end]
        end
        viewmin = minimum(ticks)
        viewmax = maximum(ticks)
    else
        minval, maxval = promote(minval, maxval)
        ticks, viewmin, viewmax =
            Gadfly.optimize_ticks(minval, maxval, extend_ticks=true)
        grids = ticks
    end

    # We use the first label function we find for any of the aesthetics. I'm not
    # positive this is the right thing to do, or would would be.
    labeler = getfield(aes, symbol(string(stat.out_var, "_label")))

    setfield(aes, symbol(string(stat.out_var, "tick")), ticks)
    setfield(aes, symbol(string(stat.out_var, "grid")), grids)
    setfield(aes, symbol(string(stat.out_var, "tick_label")), labeler)

    viewmin_var = symbol(string(stat.out_var, "viewmin"))
    if getfield(aes, viewmin_var) === nothing ||
       getfield(aes, viewmin_var) > viewmin
        setfield(aes, viewmin_var, viewmin)
    end

    viewmax_var = symbol(string(stat.out_var, "viewmax"))
    if getfield(aes, viewmax_var) === nothing ||
       getfield(aes, viewmax_var) < viewmax
        setfield(aes, viewmax_var, viewmax)
    end

    nothing
end

immutable BoxplotStatistic <: Gadfly.StatisticElement
end


element_aesthetics(::BoxplotStatistic) = [:x, :y]


const boxplot = BoxplotStatistic


function apply_statistic(stat::BoxplotStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("BoxplotStatistic", aes, :y)

    groups = Dict()

    aes_x = aes.x === nothing ? [nothing] : aes.x
    aes_color = aes.color === nothing ? [nothing] : aes.color

    T = eltype(aes.y)
    for (x, y, c) in zip(cycle(aes_x), aes.y, cycle(aes_color))
        if !haskey(groups, (x, c))
            groups[(x, c)] = Array(T, 0)
        end
        push!(groups[(x, c)], y)
    end

    m = length(groups)
    aes.middle = Array(T, m)
    aes.lower_hinge = Array(T, m)
    aes.upper_hinge = Array(T, m)
    aes.lower_fence = Array(T, m)
    aes.upper_fence = Array(T, m)
    aes.outliers = Vector{T}[]

    for (i, ((x, c), ys)) in enumerate(groups)
        sort!(ys)
        aes.lower_hinge[i], aes.middle[i], aes.upper_hinge[i] =
                quantile!(ys, [0.25, 0.5, 0.75])
        iqr = aes.upper_hinge[i] - aes.lower_hinge[i]

        idx = searchsortedfirst(ys, aes.lower_hinge[i] - 1.5iqr)
        aes.lower_fence[i] = ys[idx]

        idx = searchsortedlast(ys, aes.upper_hinge[i] + 1.5iqr)
        aes.upper_fence[i] = ys[idx]

        push!(aes.outliers,
             filter(y -> y < aes.lower_fence[i] || y > aes.upper_fence[i], ys))
    end

    if !is(aes.x, nothing)
        aes.x = PooledDataArray(Int64[x for (x, c) in keys(groups)])
    end

    if !is(aes.color, nothing)
        aes.color = PooledDataArray(ColorValue[c for (x, c) in keys(groups)],
                                    levels(aes.color))
    end

    nothing
end



immutable SmoothStatistic <: Gadfly.StatisticElement
    method::Symbol
    smoothing::Float64

    function SmoothStatistic(; method::Symbol=:loess, smoothing::Float64=0.75)
        new(method, smoothing)
    end
end


const smooth = SmoothStatistic


element_aesthetics(::SmoothStatistic) = [:x, :y]


function apply_statistic(stat::SmoothStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Stat.smooth", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Stat.smooth", aes, :x, :y)

    if stat.method != :loess
        error("The only Stat.smooth method currently supported is loess.")
    end

    num_steps = 750

    if aes.color === nothing
        x_min, x_max = minimum(aes.x), maximum(aes.x)

        if x_min == x_max
            error("Stat.smooth requires more than one distinct x value")
        end

        # loess can't predict points <x_min or >x_max. Make sure that doesn't
        # happen through a floating point fluke
        nudge = 1e-5 * (x_max - x_min)

        local xs, ys
        try
            xs = convert(Vector{Float64}, aes.x)
            ys = convert(Vector{Float64}, aes.y)
        catch
            error("Stat.loess requires that x and y be bound to arrays of plain numbers.")
        end

        aes.x = collect((x_min + nudge):((x_max - x_min) / num_steps):(x_max - nudge))
        aes.y = predict(loess(xs, ys, span=stat.smoothing), aes.x)
    else
        groups = Dict()
        aes_color = aes.color === nothing ? [nothing] : aes.color
        for (x, y, c) in zip(aes.x, aes.y, cycle(aes_color))
            if !haskey(groups, c)
                groups[c] = (Float64[], Float64[])
            end

            try
                push!(groups[c][1], x)
                push!(groups[c][2], y)
            catch
                error("Stat.loess requires that x and y be bound to arrays of plain numbers.")
            end
        end

        aes.x = Array(Float64, length(groups) * num_steps)
        aes.y = Array(Float64, length(groups) * num_steps)
        colors = Array(ColorValue, length(groups) * num_steps)

        for (i, (c, (xs, ys))) in enumerate(groups)
            x_min, x_max = minimum(xs), maximum(xs)
            if x_min == x_max
                error("Stat.smooth requires more than one distinct x value")
            end
            nudge = 1e-5 * (x_max - x_min)
            steps = collect((x_min + nudge):((x_max - x_min) / num_steps):(x_max - nudge))

            for (j, (x, y)) in enumerate(zip(steps, predict(loess(xs, ys, span=stat.smoothing), steps)))
                aes.x[(i - 1) * num_steps + j] = x
                aes.y[(i - 1) * num_steps + j] = y
                colors[(i - 1) * num_steps + j] = c
            end
        end
        aes.color = PooledDataArray(colors)
    end
end

end # module Stat

