module Stat

import Gadfly
import StatsBase
import Contour
using Color
using Compose
using DataArrays
using DataStructures
using Hexagons
using Loess

import Gadfly: Scale, Coord, element_aesthetics, default_scales, isconcrete,
               nonzero_length, setfield!
import KernelDensity
import Distributions: Uniform, Distribution, qqbuild
import Iterators: chain, cycle, product, partition, distinct

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
    orientation::Symbol
    density::Bool

    function HistogramStatistic(; bincount=nothing,
                                  minbincount=3,
                                  maxbincount=150,
                                  orientation::Symbol=:vertical,
                                  density::Bool=false)
        if bincount != nothing
            new(bincount, bincount, orientation, density)
        else
            new(minbincount, maxbincount, orientation, density)
        end
    end
end


element_aesthetics(::HistogramStatistic) = [:x]

function default_scales(stat::HistogramStatistic)
    if stat.orientation == :vertical
        return [Gadfly.Scale.y_continuous()]
    else
        return [Gadfly.Scale.x_continuous()]
    end
end

const histogram = HistogramStatistic


function apply_statistic(stat::HistogramStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    if stat.orientation == :horizontal
        var = :y
        othervar = :x
        minvar = :ymin
        maxvar = :ymax
        drawmaxvar = :xdrawmax
        labelvar = :x_label
    else
        var = :x
        othervar = :y
        minvar = :xmin
        maxvar = :xmax
        drawmaxvar = :ydrawmax
        labelvar = :y_label
    end

    Gadfly.assert_aesthetics_defined("HistogramStatistic", aes, var)

    values = getfield(aes, var)
    if stat.minbincount > stat.maxbincount
        error("Histogram minbincount > maxbincount")
    end

    if isempty(getfield(aes, var))
        setfield!(aes, minvar, Float64[1.0])
        setfield!(aes, maxvar, Float64[1.0])
        setfield!(aes, var, Float64[1.0])
        setfield!(aes, othervar, Float64[0.0])
        return
    end

    if haskey(scales, var) && isa(scales[var], Scale.DiscreteScale)
        isdiscrete = true
        x_min = minimum(values)
        x_max = maximum(values)
        d = x_max - x_min + 1
        bincounts = zeros(Int, d)
        for x in values
            bincounts[x - x_min + 1] += 1
        end
    else
        isdiscrete = false
        value_set = collect(Set(values[Bool[Gadfly.isconcrete(v) for v in values]]))
        sort!(value_set)

        if  length(value_set) / length(values) < 0.9
            d, bincounts, x_max = choose_bin_count_1d_discrete(
                        values, value_set, stat.minbincount, stat.maxbincount)
        else
            d, bincounts, x_max = choose_bin_count_1d(
                        values, stat.minbincount, stat.maxbincount)
        end

        if stat.density
            x_min = Gadfly.concrete_minimum(values)
            span = x_max - x_min
            binwidth = span / d
            bincounts ./= sum(bincounts) * binwidth
        end
    end

    x_min = Gadfly.concrete_minimum(values)
    binwidth = isdiscrete ? 1 : (x_max - x_min) / d

    if aes.color === nothing
        setfield!(aes, othervar, Array(Float64, d))
        if isdiscrete
            setfield!(aes, var, collect(Int, 1:d))
            setfield!(aes, othervar, bincounts)
        else
            setfield!(aes, minvar, Array(isdiscrete ? Int : Float64, d))
            setfield!(aes, maxvar, Array(isdiscrete ? Int : Float64, d))
            setfield!(aes, var, Array(isdiscrete ? Int : Float64, d))
            for j in 1:d
                getfield(aes, minvar)[j] = x_min + (j - 1) * binwidth
                getfield(aes, maxvar)[j] = x_min + j * binwidth
                getfield(aes, var)[j] = x_min + (j - 0.5) * binwidth
                getfield(aes, othervar)[j] = bincounts[j]
            end
        end
    else
        groups = Dict()
        for (x, c) in zip(values, cycle(aes.color))
            if !Gadfly.isconcrete(x)
                continue
            end

            if !haskey(groups, c)
                groups[c] = Float64[x]
            else
                push!(groups[c], x)
            end
        end

        if isdiscrete
            setfield!(aes, var, Array(Int, d * length(groups)))
        else
            setfield!(aes, minvar, Array(isdiscrete ? Int : Float64, d * length(groups)))
            setfield!(aes, maxvar, Array(isdiscrete ? Int : Float64, d * length(groups)))
            setfield!(aes, var, Array(isdiscrete ? Int : Float64, d * length(groups)))
        end

        setfield!(aes, othervar, Array(Float64, d * length(groups)))
        colors = Array(RGB{Float32}, d * length(groups))

        x_min = Gadfly.concrete_minimum(values)
        x_span = x_max - x_min
        stack_height = zeros(Int, d)
        for (i, (c, xs)) in enumerate(groups)
            fill!(bincounts, 0)
            for x in xs
                if !Gadfly.isconcrete(x)
                    continue
                end
                if isdiscrete
                    bincounts[int(x)] += 1
                else
                    bin = max(1, min(d, int(ceil((x - x_min) / binwidth))))
                    bincounts[bin] += 1
                end
            end

            if stat.density
                binwidth = x_span / d
                bincounts ./= sum(bincounts) * binwidth
            end

            stack_height += bincounts[1:d]

            if isdiscrete
                for j in 1:d
                    idx = (i-1)*d + j
                    getfield(aes, var)[idx] = j
                    getfield(aes, othervar)[idx] = bincounts[j]
                    colors[idx] = c
                end
            else
                for j in 1:d
                    idx = (i-1)*d + j
                    getfield(aes, minvar)[idx] = x_min + (j - 1) * binwidth
                    getfield(aes, maxvar)[idx] = x_min + j * binwidth
                    getfield(aes, var)[idx] = x_min + (j - 0.5) * binwidth
                    getfield(aes, othervar)[idx] = bincounts[j]
                    colors[idx] = c
                end
            end
        end

        drawmax = float64(maximum(stack_height))
        aes_drawmax = getfield(aes, drawmaxvar)
        if aes_drawmax === nothing || aes_drawmax < drawmax
            setfield!(aes, drawmaxvar, drawmax)
        end

        aes.color = PooledDataArray(colors)
    end

    if haskey(scales, othervar)
        data = Gadfly.Data()
        setfield!(data, othervar, getfield(aes, othervar))
        Scale.apply_scale(scales[othervar], [aes], data)
    else
        setfield!(aes, labelvar, Scale.identity_formatter)
    end
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

default_scales(::DensityStatistic) = [Gadfly.Scale.y_continuous()]

function apply_statistic(stat::DensityStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("DensityStatistic", aes, :x)

    if aes.color === nothing
        if !isa(aes.x[1], Real)
            error("Kernel density estimation only works on Real types.")
        end

        x_f64 = collect(Float64, aes.x)
        # When will stat.n ever be <= 1? Seems pointless
        # certainly its length will always be 1
        window = stat.n > 1 ? KernelDensity.default_bandwidth(x_f64) : 0.1
        f = KernelDensity.kde(x_f64, bandwidth=window, npoints=stat.n)
        aes.x = collect(Float64, f.x)
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

        colors = Array(RGB{Float32}, 0)
        aes.x = Array(Float64, 0)
        aes.y = Array(Float64, 0)
        for (c, xs) in groups
            window = stat.n > 1 ? KernelDensity.default_bandwidth(xs) : 0.1
            f = KernelDensity.kde(xs, bandwidth=window, npoints=stat.n)
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
    for cnt in transpose(bincounts)
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

    # fixed ticks, or nothing
    ticks::Union(Nothing, AbstractArray)
end


function xticks(ticks::Union(Nothing, AbstractArray)=nothing)
    TickStatistic([:x, :xmin, :xmax, :xdrawmin, :xdrawmax], "x", ticks)
end


function yticks(ticks::Union(Nothing, AbstractArray)=nothing)
    TickStatistic(
        [:y, :ymin, :ymax, :middle, :lower_hinge, :upper_hinge,
         :lower_fence, :upper_fence, :ydrawmin, :ydrawmax], "y", ticks)
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
function apply_statistic(stat::TickStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    if isa(coord, Coord.SubplotGrid)
        error("TickStatistic cannot be applied to subplot coordinates.")
    end

    in_group_var = symbol(string(stat.out_var, "group"))
    minval, maxval = nothing, nothing
    in_values = {}
    categorical = (:x in stat.in_vars && Scale.iscategorical(scales, :x)) ||
                  (:y in stat.in_vars && Scale.iscategorical(scales, :y))

    for var in stat.in_vars
        vals = getfield(aes, var)
        if vals != nothing && eltype(vals) != Function
            if minval == nothing
                minval = first(vals)
            end
            if maxval == nothing
                maxval = first(vals)
            end
            T = promote_type(typeof(minval), typeof(maxval))
            T = promote_type(T, eltype(vals))
            minval = convert(T, minval)
            maxval = convert(T, maxval)

            if stat.out_var == "x"
                dsize = aes.xsize === nothing ? [nothing] : aes.xsize
            elseif stat.out_var == "y"
                dsize = aes.ysize === nothing ? [nothing] : aes.ysize
            else
                dsize = [nothing]
            end

            size = aes.size === nothing ? [nothing] : aes.size

            minval, maxval = apply_statistic_typed(minval, maxval, vals, size, dsize)
            push!(in_values, vals)
        end
    end

    if isempty(in_values)
        return
    end

    in_values = chain(in_values...)

    # consider forced tick marks
    if stat.ticks != nothing
        minval = min(minval, minimum(stat.ticks))
        maxval = max(maxval, maximum(stat.ticks))
    end

    # TODO: handle the outliers aesthetic

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
    if stat.ticks != nothing
        grids = ticks = stat.ticks
        viewmin = minval
        viewmax = maxval
        tickvisible = fill(true, length(ticks))
        tickscale = fill(1.0, length(ticks))
    elseif categorical
        ticks = Set()
        for val in in_values
            push!(ticks, val)
        end
        ticks = Float64[t for t in ticks]
        sort!(ticks)
        grids = (ticks .- 0.5)[2:end]
        viewmin = minimum(ticks)
        viewmax = maximum(ticks)
        tickvisible = fill(true, length(ticks))
        tickscale = fill(1.0, length(ticks))
    else
        minval, maxval = promote(minval, maxval)

        ticks, viewmin, viewmax =
            Gadfly.optimize_ticks(minval, maxval, extend_ticks=true)
        grids = ticks
        multiticks = Gadfly.multilevel_ticks(viewmin - (viewmax - viewmin),
                                             viewmax + (viewmax - viewmin))
        tickcount = length(ticks) + sum([length(ts) for ts in values(multiticks)])
        tickvisible = Array(Bool, tickcount)
        tickscale = Array(Float64, tickcount)
        i = 1
        for t in ticks
            tickscale[i] = 1.0
            tickvisible[i] = viewmin <= t <= viewmax
            i += 1
        end

        for (scale, ts) in multiticks
            for t in ts
                push!(ticks, t)
                tickvisible[i] = false
                tickscale[i] = scale
                i += 1
            end
        end
    end

    # We use the first label function we find for any of the aesthetics. I'm not
    # positive this is the right thing to do, or would would be.
    labeler = getfield(aes, symbol(string(stat.out_var, "_label")))

    setfield!(aes, symbol(string(stat.out_var, "tick")), ticks)
    setfield!(aes, symbol(string(stat.out_var, "grid")), grids)
    setfield!(aes, symbol(string(stat.out_var, "tick_label")), labeler)
    setfield!(aes, symbol(string(stat.out_var, "tickvisible")), tickvisible)
    setfield!(aes, symbol(string(stat.out_var, "tickscale")), tickscale)

    viewmin_var = symbol(string(stat.out_var, "viewmin"))
    if getfield(aes, viewmin_var) === nothing ||
       getfield(aes, viewmin_var) > viewmin
        setfield!(aes, viewmin_var, viewmin)
    end

    viewmax_var = symbol(string(stat.out_var, "viewmax"))
    if getfield(aes, viewmax_var) === nothing ||
       getfield(aes, viewmax_var) < viewmax
        setfield!(aes, viewmax_var, viewmax)
    end

    nothing
end

function apply_statistic_typed{T}(minval::T, maxval::T, vals, size, dsize)
#     for (val, s, ds) in zip(vals, cycle(size), cycle(dsize))
    lensize  = length(size)
    lendsize = length(dsize)
    for (i, val) in enumerate(vals)
        if !Gadfly.isconcrete(val) || !isfinite(val)
            continue
        end

        s = size[mod1(i, lensize)]
        ds = dsize[mod1(i, lendsize)]

        minval, maxval = minvalmaxval(minval, maxval, convert(T, val), s, ds)
    end
    minval, maxval
end

function apply_statistic_typed{T}(minval, maxval, vals::DataArray{T}, size, dsize)
    lensize  = length(size)
    lendsize = length(dsize)
    for i = 1:length(vals)
        if vals.na[i]
            continue
        end

        val::T = vals.data[i]
        s = size[mod1(i, lensize)]
        ds = dsize[mod1(i, lendsize)]

        minval, maxval = minvalmaxval(minval, maxval, val, s, ds)
    end
    minval, maxval
end

function minvalmaxval{T}(minval::T, maxval::T, val, s, ds)
    if val < minval || !isfinite(minval)
        minval = val
    end

    if val > maxval || !isfinite(maxval)
        maxval = val
    end

    if s != nothing
        minval = min(minval, val - s)::T
        maxval = max(maxval, val + s)::T
    end

    if ds != nothing
        minval = min(minval, val - ds)::T
        maxval = max(maxval, val + ds)::T
    end

    minval, maxval
end

immutable BoxplotStatistic <: Gadfly.StatisticElement
end


element_aesthetics(::BoxplotStatistic) = [:x, :y]


const boxplot = BoxplotStatistic


function apply_statistic(stat::BoxplotStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    if aes.y === nothing
        Gadfly.assert_aesthetics_defined("BoxplotStatistic", aes,
            :x, :lower_hinge, :upper_hinge, :lower_fence, :upper_fence)

        aes_color = aes.color === nothing ? [nothing] : aes.color
        groups = {}
        for (x, c) in zip(aes.x, cycle(aes_color))
            push!(groups, (x, c))
        end

        if !is(aes.color, nothing)
            aes.color = PooledDataArray(ColorValue[c for (x, c) in groups],
                                        levels(aes.color))
        end

        return
    end

    if aes.x === nothing
        aes_x = [1]
        aes.x_label = x -> fill("", length(x))
    else
        aes_x = aes.x
    end
    aes_color = aes.color === nothing ? [nothing] : aes.color

    T = isempty(aes.y) ? eltype(aes.y) : typeof(aes.y[1] / 1)
    groups = DefaultOrderedDict(() -> T[])

    for (x, y, c) in zip(cycle(aes_x), aes.y, cycle(aes_color))
        push!(groups[(x, c)], y)
    end

    if aes.y != nothing
        m = length(groups)
        aes.x = Array(eltype(aes.x), m)
        aes.middle = Array(T, m)
        aes.lower_hinge = Array(T, m)
        aes.upper_hinge = Array(T, m)
        aes.lower_fence = Array(T, m)
        aes.upper_fence = Array(T, m)
        aes.outliers = Vector{T}[]

        for (i, ((x, c), ys)) in enumerate(groups)
            sort!(ys)

            aes.x[i] = x
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
    end

    if isa(aes_x, PooledDataArray)
        aes.x = PooledDataArray(aes.x, aes_x.pool)
    end

    if !is(aes.color, nothing)
        aes.color = PooledDataArray(RGB{Float32}[c for (x, c) in keys(groups)],
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

    if !(stat.method in [:loess,:lm])
        error("The only Stat.smooth methods currently supported are loess and lm.")
    end

    num_steps = 750

    if aes.color === nothing
        x_min, x_max = minimum(aes.x), maximum(aes.x)

        if x_min == x_max
            error("Stat.smooth requires more than one distinct x value")
        end

        local xs, ys

        try
            xs = convert(Vector{Float64}, aes.x)
            ys = convert(Vector{Float64}, aes.y)
        catch e
            error("Stat.loess and Stat.lm require that x and y be bound to arrays of plain numbers.")
        end

        # loess can't predict points <x_min or >x_max. Make sure that doesn't
        # happen through a floating point fluke
        nudge = 1e-5 * (x_max - x_min)
        aes.x = collect((x_min + nudge):((x_max - x_min) / num_steps):(x_max - nudge))

        if stat.method == :loess
            aes.y = predict(loess(xs, ys, span=stat.smoothing), aes.x)
        elseif stat.method == :lm
            lmcoeff = linreg(xs,ys)
            aes.y = lmcoeff[2].*aes.x .+ lmcoeff[1]
        end
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
                error("Stat.loess and Stat.lm require that x and y be bound to arrays of plain numbers.")
            end
        end

        aes.x = Array(Float64, length(groups) * num_steps)
        aes.y = Array(Float64, length(groups) * num_steps)
        colors = Array(RGB{Float32}, length(groups) * num_steps)

        for (i, (c, (xs, ys))) in enumerate(groups)
            x_min, x_max = minimum(xs), maximum(xs)
            if x_min == x_max
                error("Stat.smooth requires more than one distinct x value")
            end
            nudge = 1e-5 * (x_max - x_min)
            steps = collect((x_min + nudge):((x_max - x_min) / num_steps):(x_max - nudge))

            if stat.method == :loess
                smoothys = predict(loess(xs, ys, span=stat.smoothing), steps)
            elseif stat.method == :lm
                lmcoeff = linreg(xs,ys)
                smoothys = lmcoeff[2].*steps .+ lmcoeff[1]
            end

            for (j, (x, y)) in enumerate(zip(steps, smoothys))
                aes.x[(i - 1) * num_steps + j] = x
                aes.y[(i - 1) * num_steps + j] = y
                colors[(i - 1) * num_steps + j] = c
            end
        end
        aes.color = PooledDataArray(colors)
    end
end


immutable HexBinStatistic <: Gadfly.StatisticElement
    xbincount::Int
    ybincount::Int

    function HexBinStatistic(; xbincount=50, ybincount=50)
        new(xbincount, ybincount)
    end
end


const hexbin = HexBinStatistic


function apply_statistic(stat::HexBinStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    xmin, xmax = minimum(aes.x), maximum(aes.x)
    ymin, ymax = minimum(aes.y), maximum(aes.y)
    xspan, yspan = xmax - xmin, ymax - ymin

    xsize = xspan / stat.xbincount
    ysize = yspan / stat.ybincount

    counts = Dict{(Any, Any), Int}()
    for (x, y) in zip(aes.x, aes.y)
        h = convert(HexagonOffsetOddR, pointhex(x - xmin + xspan/2,
                                                y - ymin + yspan/2,
                                                xsize, ysize))
        idx = (h.q, h.r)
        if !haskey(counts, idx)
            counts[idx] = 1
        else
            counts[idx] += 1
        end
    end

    N = length(counts)
    aes.x = Array(Float64, N)
    aes.y = Array(Float64, N)
    data = Gadfly.Data()
    data.color = Array(Int, N)
    k = 1
    for (idx, cnt) in counts
        x, y = center(HexagonOffsetOddR(idx[1], idx[2]), xsize, ysize,
                      xmin - xspan/2, ymin - yspan/2)
        aes.x[k] = x
        aes.y[k] = y
        data.color[k] = cnt
        k += 1
    end
    aes.xsize = [xsize]
    aes.ysize = [ysize]

    color_scale = scales[:color]
    if !(typeof(color_scale) <: Scale.ContinuousColorScale)
        error("HexBinGeometry requires a continuous color scale.")
    end

    Scale.apply_scale(color_scale, [aes], data)
end


function default_scales(::HexBinStatistic)
    return [Gadfly.Scale.continuous_color()]
end


immutable StepStatistic <: Gadfly.StatisticElement
    direction::Symbol

    function StepStatistic(; direction::Symbol=:hv)
        return new(direction)
    end
end

const step = StepStatistic


function element_aesthetics(::StepStatistic)
    return [:x, :y]
end


function apply_statistic(stat::StepStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("StepStatistic", aes, :x)
    Gadfly.assert_aesthetics_defined("StepStatistic", aes, :y)
    Gadfly.assert_aesthetics_equal_length("StepStatistic", aes, :x, :y)

    points = collect(zip(aes.x, aes.y))
    sort!(points, by=first)
    n = length(points)
    x_step = Array(eltype(aes.x), 2n - 1)
    y_step = Array(eltype(aes.y), 2n - 1)

    for i in 1:(2n-1)
        if isodd(i)
            x_step[i] = points[div(i-1,2)+1][1]
            y_step[i] = points[div(i-1,2)+1][2]
        elseif stat.direction == :hv
            x_step[i] = points[div(i-1,2)+2][1]
            y_step[i] = points[div(i-1,2)+1][2]
        else
            x_step[i] = points[div(i-1,2)+1][1]
            y_step[i] = points[div(i-1,2)+2][2]
        end
    end

    aes.x = x_step
    aes.y = y_step
end


immutable FunctionStatistic <: Gadfly.StatisticElement
    # Number of points to evaluate the function at
    num_samples::Int

    function FunctionStatistic(; num_samples=250)
        return new(num_samples)
    end
end


const func = FunctionStatistic


function default_scales(::FunctionStatistic)
    return [Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous()]
end


function element_aesthetics(::FunctionStatistic)
    return [:y, :xmin, :xmax, :ymin, :ymax]
end


function apply_statistic(stat::FunctionStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("FunctionStatistic", aes, :y)
    Gadfly.assert_aesthetics_defined("FunctionStatistic", aes, :xmin)
    Gadfly.assert_aesthetics_defined("FunctionStatistic", aes, :xmax)
    Gadfly.assert_aesthetics_equal_length("FunctionStatistic", aes, :xmin, :xmax)

    aes.x = Array(Float64, length(aes.y) * stat.num_samples)
    ys = Array(Float64, length(aes.y) * stat.num_samples)

    i = 1
    for (f, xmin, xmax) in zip(aes.y, cycle(aes.xmin), cycle(aes.xmax))
        for x in linspace(xmin, xmax, stat.num_samples)
            aes.x[i] = x
            ys[i] = f(x)
            i += 1
        end
    end

    # color was bound explicitly
    if aes.color != nothing
        func_color = aes.color
        aes.color = DataArray(eltype(aes.color), length(aes.y) * stat.num_samples)
        groups = DataArray(Int, length(aes.y) * stat.num_samples)
        for i in 1:length(aes.y)
            aes.color[1+(i-1)*stat.num_samples:i*stat.num_samples] = func_color[i]
            groups[1+(i-1)*stat.num_samples:i*stat.num_samples] = i
        end
        aes.group = PooledDataArray(groups)
    elseif length(aes.y) > 1 && haskey(scales, :color)
        data = Gadfly.Data()
        data.color = Array(String, length(aes.y) * stat.num_samples)
        for i in 1:length(aes.y)
            fname = "f<sub>$(i)</sub>"
            data.color[1+(i-1)*stat.num_samples:i*stat.num_samples] = fname
        end
        Scale.apply_scale(scales[:color], [aes], data)
    end

    data = Gadfly.Data()
    data.y = ys
    Scale.apply_scale(scales[:y], [aes], data)
end

immutable ContourStatistic <: Gadfly.StatisticElement
    levels
    samples::Int

    function ContourStatistic(; n=15, samples=150)
        new(n, samples)
    end

    function ContourStatistic(; levels=15, samples=150)
        new(levels, samples)
    end
end


element_aesthetics(::ContourStatistic) = [:z, :xmin, :xmax, :ymin, :ymax]


const contour = ContourStatistic


function default_scales(::ContourStatistic)
    return [Gadfly.Scale.z_func(), Gadfly.Scale.x_continuous(),
            Gadfly.Scale.y_continuous(),
            Gadfly.Scale.continuous_color_gradient()]
end


function apply_statistic(stat::ContourStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    xs = aes.x === nothing ? nothing : convert(Vector{Float64}, aes.x)
    ys = aes.y === nothing ? nothing : convert(Vector{Float64}, aes.y)

    if typeof(aes.z) <: Function
        if xs == nothing && aes.xmin != nothing && aes.xmax != nothing
            xs = linspace(aes.xmin[1], aes.xmax[1], stat.samples)
        end

        if ys == nothing && aes.ymin != nothing && aes.ymax != nothing
            ys = linspace(aes.ymin[1], aes.ymax[1], stat.samples)
        end

        zs = Float64[aes.z(x, y) for x in xs, y in ys]

    elseif typeof(aes.z) <: Matrix
        zs = convert(Matrix{Float64}, aes.z)

        if xs == nothing
            xs = float([1:size(zs)[1]])
        end
        if ys == nothing
            ys = float([1:size(zs)[2]])
        end
        if size(zs) != (length(xs), length(ys))
            error("Stat.contour requires dimension of z to be length(x) by length(y)")
        end
    else
        error("Stat.contour requires either a matrix or a function")
    end

    levels = Float64[]
    contour_xs = eltype(xs)[]
    contour_ys = eltype(ys)[]

    groups = PooledDataArray(Int[])
    group = 0
    for contour in Contour.contours(xs, ys, zs, stat.levels)
        for curve in contour.lines
            for v in curve.vertices
                push!(contour_xs, v[1])
                push!(contour_ys, v[2])
                push!(levels, contour.level)
                push!(groups, group)
            end
            group += 1
        end
    end

    aes.group = groups
    color_scale = get(scales, :color, Gadfly.Scale.continuous_color_gradient())
    Scale.apply_scale(color_scale, [aes], Gadfly.Data(color=levels))
    Scale.apply_scale(scales[:x], [aes],  Gadfly.Data(x=contour_xs))
    Scale.apply_scale(scales[:y], [aes], Gadfly.Data(y=contour_ys))
end


immutable QQStatistic <: Gadfly.StatisticElement
end

element_aesthetics(::QQStatistic) = [:x, :y]

const qq = QQStatistic

function default_scales(::QQStatistic)
    return [Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous]
end

function apply_statistic(stat::QQStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Stat.qq", aes, :x, :y)

    # NOTES:
    #
    # apply_scales happens before apply_statistics, so we need to handle in
    # apply_scales the Distributions that might be bound to x and y... By
    # analogy with Stat.func, we can add a check in apply_statistic which defers
    # application.  Stat.func though requires an ARRAY of Functions, and doesn't
    # work on naked functions bound to aes.y.  If we want to bind Distributions,
    # we'd need to extend the types that are allowed for aes.y/.x (e.g. change
    # type of Aesthetics fields x and y).  Right now these are of type
    # NumericalOrCategoricalAesthetic.  The .x and .y fields are the _only_
    # place where this type is used, but I'm not sure if there's a reason that
    # changing this typealias would be a bad idea...for now I've just used a
    # direct `Union(NumericalOrCategoricalAesthetic, Distribution)`.
    #
    # TODO:
    #
    # Grouping by color etc.?

    # a little helper function to convert either numeric or distribution
    # variables to a format suitable to input to qqbuild.
    toVecOrDist = v -> typeof(v) <: Distribution ? v : convert(Vector{Float64}, v)

    # check and convert :x and :y to proper types for input to qqbuild
    local xs, ys
    try
        (xs, ys) = map(toVecOrDist, (aes.x, aes.y))
    catch e
        error("Stat.qq requires that x and y be bound to either a Distribution or to arrays of plain numbers.")
    end

    qqq = qqbuild(xs, ys)

    aes.x = qqq.qx
    aes.y = qqq.qy

    # apply_scale to Distribution-bound aesthetics is deferred, so re-apply here
    # (but only for Distribution, numeric data is already scaled).  Only one of
    # :x or :y can be a Distribution since qqbuild will throw an error for two
    # Distributions.
    data = Gadfly.Data()
    if typeof(xs) <: Distribution
        data.x = aes.x
        Scale.apply_scale(scales[:x], [aes], data)
    elseif typeof(ys) <: Distribution
        data.y = aes.y
        Scale.apply_scale(scales[:y], [aes], data)
    end

end


end # module Stat
