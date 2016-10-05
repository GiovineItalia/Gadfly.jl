module Stat

import Gadfly
import StatsBase
import Contour
using Colors
using Compat
using Compose
using DataArrays
using DataStructures
using Hexagons
using Loess

import Gadfly: Scale, Coord, input_aesthetics, output_aesthetics,
               default_scales, isconcrete, nonzero_length, setfield!
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


# Determine bounds of bars positioned at the given values.
function barminmax(values, iscontinuous::Bool)
    minvalue, maxvalue = minimum(values), maximum(values)
    span_type = typeof((maxvalue - minvalue) / 1.0)
    barspan = one(span_type)

    if iscontinuous && length(values) > 1
        sorted_values = sort(values)
        T = typeof(sorted_values[2] - sorted_values[1])
        z = zero(T)
        minspan = z
        for i in 2:length(values)
            span = sorted_values[i] - sorted_values[i-1]
            if span > z && (span < minspan || minspan == z)
                minspan = span
            end
        end
        barspan = minspan
    end
    position_type = promote_type(typeof(barspan/2.0), eltype(values))
    minvals = Array(position_type, length(values))
    maxvals = Array(position_type, length(values))

    for (i, x) in enumerate(values)
        minvals[i] = x - barspan/2.0
        maxvals[i] = x + barspan/2.0
    end

    return minvals, maxvals
end


immutable RectbinStatistic <: Gadfly.StatisticElement
end


const rectbin = RectbinStatistic


function input_aesthetics(stat::RectbinStatistic)
    return [:x, :y]
end


function output_aesthetics(stat::RectbinStatistic)
    return [:xmin, :xmax, :ymin, :ymax]
end


function apply_statistic(stat::RectbinStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("RectbinStatistic", aes, :x, :y)

    isxcontinuous = haskey(scales, :x) && isa(scales[:x], Scale.ContinuousScale)
    isycontinuous = haskey(scales, :y) && isa(scales[:y], Scale.ContinuousScale)

    xminvals, xmaxvals = barminmax(aes.x, isxcontinuous)
    yminvals, ymaxvals = barminmax(aes.y, isycontinuous)

    aes.xmin = xminvals
    aes.xmax = xmaxvals
    aes.ymin = yminvals
    aes.ymax = ymaxvals

    if !isxcontinuous
        aes.pad_categorical_x = Nullable(false)
    end
    if !isycontinuous
        aes.pad_categorical_y = Nullable(false)
    end
end


immutable BarStatistic <: Gadfly.StatisticElement
    position::Symbol # :dodge or :stack
    orientation::Symbol # :horizontal or :vertical
end


function BarStatistic(; position::Symbol=:stack,
                        orientation::Symbol=:vertical)
    return BarStatistic(position, orientation)
end


function input_aesthetics(stat::BarStatistic)
    return stat.orientation == :vertical ? [:x] : [:y]
end


function output_aesthetics(stat::BarStatistic)
    return stat.orientation == :vertical ? [:ymin, :ymax] : [:xmin, :xmax]
end


function default_scales(stat::BarStatistic)
    if stat.orientation == :vertical
        return [Gadfly.Scale.y_continuous()]
    else
        return [Gadfly.Scale.x_continuous()]
    end
end


const bar = BarStatistic


function apply_statistic(stat::BarStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("BarStatistic", aes, :x, :y)

    if stat.orientation == :horizontal
        var = :y
        othervar = :x
        minvar = :ymin
        maxvar = :ymax
        viewminvar = :xviewmin
        viewmaxvar = :xviewmax
        other_viewminvar = :yviewmin
        other_viewmaxvar = :yviewmax
        labelvar = :x_label
    else
        var = :x
        othervar = :y
        minvar = :xmin
        maxvar = :xmax
        viewminvar = :yviewmin
        viewmaxvar = :yviewmax
        other_viewminvar = :xviewmin
        other_viewmaxvar = :xviewmax
        labelvar = :y_label
    end

    values = getfield(aes, var)
    if isempty(getfield(aes, var))
      setfield!(aes, minvar, Float64[1.0])
      setfield!(aes, maxvar, Float64[1.0])
      setfield!(aes, var, Float64[1.0])
      setfield!(aes, othervar, Float64[0.0])
      return
    end

    iscontinuous = haskey(scales, var) && isa(scales[var], Scale.ContinuousScale)

    if getfield(aes, minvar) == nothing || getfield(aes, maxvar) == nothing
        minvals, maxvals = barminmax(values, iscontinuous)

        setfield!(aes, minvar, minvals)
        setfield!(aes, maxvar, maxvals)
    end

    z = zero(eltype(getfield(aes, othervar)))
    if getfield(aes, viewminvar) == nothing && z < minimum(getfield(aes, othervar))
        setfield!(aes, viewminvar, z)
    elseif getfield(aes, viewmaxvar) == nothing && z > maximum(getfield(aes, othervar))
        setfield!(aes, viewmaxvar, z)
    end

    if !iscontinuous
        if stat.orientation == :horizontal
            aes.pad_categorical_y = Nullable(false)
        else
            aes.pad_categorical_x = Nullable(false)
        end
    end
end


immutable HistogramStatistic <: Gadfly.StatisticElement
    minbincount::Int
    maxbincount::Int
    position::Symbol # :dodge or :stack
    orientation::Symbol
    density::Bool

    function HistogramStatistic(; bincount=nothing,
                                  minbincount=3,
                                  maxbincount=150,
                                  position::Symbol=:stack,
                                  orientation::Symbol=:vertical,
                                  density::Bool=false)
        if bincount != nothing
            new(bincount, bincount, position, orientation, density)
        else
            new(minbincount, maxbincount, position, orientation, density)
        end
    end
end


function input_aesthetics(stat::HistogramStatistic)
    return stat.orientation == :vertical ? [:x] : [:y]
end


function output_aesthetics(stat::HistogramStatistic)
    return stat.orientation == :vertical ? [:x, :y, :ymin, :ymax] : [:y, :x, :xmin, :xmax]
end


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
        viewminvar = :xviewmin
        viewmaxvar = :xviewmax
        labelvar = :x_label
    else
        var = :x
        othervar = :y
        minvar = :xmin
        maxvar = :xmax
        viewminvar = :yviewmin
        viewmaxvar = :yviewmax
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
        x_min -= 0.5 # adjust the left side of the bar
        binwidth = 1.0
    else
        x_min = Gadfly.concrete_minimum(values)

        isdiscrete = false
        if estimate_distinct_proportion(values) <= 0.9
            value_set = sort!(collect(Set(values[Bool[Gadfly.isconcrete(v) for v in values]])))
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
            bincounts = bincounts ./ sum(bincounts) * binwidth
        end

        binwidth = (x_max - x_min) / d
    end

    if aes.color === nothing
        T = typeof(x_min + 1*binwidth)
        setfield!(aes, othervar, Array(Float64, d))
        setfield!(aes, minvar, Array(T, d))
        setfield!(aes, maxvar, Array(T, d))
        setfield!(aes, var, Array(T, d))
        for j in 1:d
            getfield(aes, minvar)[j] = x_min + (j - 1) * binwidth
            getfield(aes, maxvar)[j] = x_min + j * binwidth
            getfield(aes, var)[j] = x_min + (j - 0.5) * binwidth
            getfield(aes, othervar)[j] = bincounts[j]
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
        T = typeof(x_min + 1*binwidth)
        setfield!(aes, minvar, Array(T, d * length(groups)))
        setfield!(aes, maxvar, Array(T, d * length(groups)))
        setfield!(aes, var, Array(T, d * length(groups)))

        setfield!(aes, othervar, Array(Float64, d * length(groups)))
        colors = Array(RGB{Float32}, d * length(groups))

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
                    bin = max(1, min(d, (@compat ceil(Int, (x - x_min) / binwidth))))
                    bincounts[bin] += 1
                end
            end

            if stat.density
                binwidth = x_span / d
                bincounts = bincounts ./ sum(bincounts) * binwidth
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

        if stat.position == :stack
            viewmax = @compat Float64(maximum(stack_height))
            aes_viewmax = getfield(aes, viewmaxvar)
            if aes_viewmax === nothing || aes_viewmax < viewmax
                setfield!(aes, viewmaxvar, viewmax)
            end
        end

        aes.color = PooledDataArray(colors)
    end

    if getfield(aes, viewminvar) === nothing
        setfield!(aes, viewminvar, 0.0)
    end

    if haskey(scales, othervar)
        data = Gadfly.Data()
        setfield!(data, othervar, getfield(aes, othervar))
        setfield!(data, viewmaxvar, getfield(aes, viewmaxvar))
        Scale.apply_scale(scales[othervar], [aes], data)

        # See issue #560. Stacked histograms on a non-linear y scale are a strange
        # thing. After some discussion, the least confusing thing is to make the stack
        # partitioned linearly. Here we make that adjustment.
        if stat.position == :stack && aes.color != nothing
            # A little trickery to figure out the scale stack height.
            data = Gadfly.Data()
            setfield!(data, othervar, stack_height)
            scaled_stackheight_aes = Gadfly.Aesthetics()
            Scale.apply_scale(scales[othervar], [scaled_stackheight_aes], data)
            scaled_stackheight = getfield(scaled_stackheight_aes, othervar)

            othervals = getfield(aes, othervar)
            for j in 1:d
                naive_stackheight = 0
                for i in 1:length(groups)
                    idx = (i-1)*d + j
                    naive_stackheight += othervals[idx]
                end

                for i in 1:length(groups)
                    idx = (i-1)*d + j
                    othervals[idx] = scaled_stackheight[j] * othervals[idx] / naive_stackheight
                end
            end
        end
    else
        setfield!(aes, labelvar, Scale.identity_formatter)
    end
end


immutable DensityStatistic <: Gadfly.StatisticElement
    # Number of points sampled
    n::Int
    # Bandwidth used for the kernel density estimation
    bw::Real

    function DensityStatistic(; n=300, bandwidth=-Inf)
        new(n, bandwidth)
    end
end


const density = DensityStatistic


function input_aesthetics(stat::DensityStatistic)
    return [:x]
end


function output_aesthetics(stat::DensityStatistic)
    return [:x, :y]
end


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

        window = stat.bw <= 0.0 ? KernelDensity.default_bandwidth(x_f64) : stat.bw
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
            window = stat.bw <= 0.0 ? KernelDensity.default_bandwidth(xs) : stat.bw
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


function input_aesthetics(stat::Histogram2DStatistic)
    return [:x, :y]
end


function output_aesthetics(stat::Histogram2DStatistic)
    return [:xmin, :ymax, :ymin, :ymax, :color]
end


default_scales(::Histogram2DStatistic, t::Gadfly.Theme=Gadfly.current_theme()) =
    [t.continuous_color_scale]


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
    wy = y_categorial ? 1 : (y_max - y_min) / dy

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
        aes.xmin, aes.xmax = barminmax(aes.x, false)
        aes.x = PooledDataArray(aes.x)
        aes.pad_categorical_x = Nullable(false)
    end

    if y_categorial
        aes.ymin, aes.ymax = barminmax(aes.y, false)
        aes.y = PooledDataArray(aes.y)
        aes.pad_categorical_y = Nullable(false)
    end

    Scale.apply_scale(color_scale, [aes], data)
    nothing
end


# Find reasonable places to put tick marks and grid lines.
immutable TickStatistic <: Gadfly.StatisticElement
    in_vars::Vector{Symbol}
    out_var::AbstractString

    granularity_weight::Float64
    simplicity_weight::Float64
    coverage_weight::Float64
    niceness_weight::Float64

    # fixed ticks, or nothing
    ticks::@compat(Union{Symbol, AbstractArray})
end


@deprecate xticks(ticks) xticks(ticks=ticks)

function xticks(; ticks::@compat(Union{Symbol, AbstractArray})=:auto,
                  granularity_weight::Float64=1/4,
                  simplicity_weight::Float64=1/6,
                  coverage_weight::Float64=1/3,
                  niceness_weight::Float64=1/4)
    TickStatistic([:x, :xmin, :xmax, :xintercept], "x",
                  granularity_weight, simplicity_weight,
                  coverage_weight, niceness_weight, ticks)
end


@deprecate yticks(ticks) yticks(ticks=ticks)

function yticks(; ticks::@compat(Union{Symbol, AbstractArray})=:auto,
                  granularity_weight::Float64=1/4,
                  simplicity_weight::Float64=1/6,
                  coverage_weight::Float64=1/3,
                  niceness_weight::Float64=1/4)
    TickStatistic(
        [:y, :ymin, :ymax, :yintercept, :middle, :lower_hinge, :upper_hinge,
         :lower_fence, :upper_fence], "y",
        granularity_weight, simplicity_weight,
        coverage_weight, niceness_weight, ticks)
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

    if isa(stat.ticks, Symbol) && stat.ticks != :auto
        error("Invalid value $(stat.ticks) for ticks parameter.")
    end

    if isa(coord, Coord.SubplotGrid)
        error("TickStatistic cannot be applied to subplot coordinates.")
    end

    # don't clobber existing ticks
    if getfield(aes, Symbol(stat.out_var, "tick")) != nothing
        return
    end

    in_group_var = Symbol(stat.out_var, "group")
    minval, maxval = nothing, nothing
    in_values = Any[]
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
    if stat.ticks != :auto
        minval = min(minval, minimum(stat.ticks))
        maxval = max(maxval, maximum(stat.ticks))
    end

    # TODO: handle the outliers aesthetic

    n = Gadfly.concrete_length(in_values)

    # check the x/yviewmin/max pesudo-aesthetics
    if stat.out_var == "x"
        if aes.xviewmin != nothing
            minval = min(minval, aes.xviewmin)
        end
        if aes.xviewmax != nothing
            maxval = max(maxval, aes.xviewmax)
        end
    elseif stat.out_var == "y"
        if aes.yviewmin != nothing
            minval = min(minval, aes.yviewmin)
        end
        if aes.yviewmax != nothing
            maxval = max(maxval, aes.yviewmax)
        end
    end

    # take into account a forced viewport in cartesian coordinates.
    strict_span = false
    if typeof(coord) == Coord.Cartesian
        if stat.out_var == "x"
            if !is(coord.xmin, nothing)
                minval = coord.xmin
                strict_span = true
            end
            if !is(coord.xmax, nothing)
                maxval = coord.xmax
                strict_span = true
            end
        elseif stat.out_var == "y"
            if !is(coord.ymin, nothing)
                minval = coord.ymin
                strict_span = true
            end
            if !is(coord.ymax, nothing)
                maxval = coord.ymax
                strict_span = true
            end
        end
    end

    # all the input values in order.
    if stat.ticks != :auto
        grids = ticks = stat.ticks
        viewmin = minval
        viewmax = maxval
        tickvisible = fill(true, length(ticks))
        tickscale = fill(1.0, length(ticks))
    elseif categorical
        ticks = Set{Int}()
        for val in in_values
            if isinteger(val) && val > 0
                push!(ticks, round(Int, val))
            end
        end
        ticks = Int[t for t in ticks]
        sort!(ticks)
        grids = (ticks .- 0.5)[2:end]
        viewmin = minimum(ticks)
        viewmax = maximum(ticks)
        tickvisible = fill(true, length(ticks))
        tickscale = fill(1.0, length(ticks))
    else
        minval, maxval = promote(minval, maxval)

        ticks, viewmin, viewmax =
            Gadfly.optimize_ticks(minval, maxval, extend_ticks=true,
                                  granularity_weight=stat.granularity_weight,
                                  simplicity_weight=stat.simplicity_weight,
                                  coverage_weight=stat.coverage_weight,
                                  niceness_weight=stat.niceness_weight,
                                  strict_span=strict_span)
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
    labeler = getfield(aes, Symbol(stat.out_var, "_label"))

    setfield!(aes, Symbol(stat.out_var, "tick"), ticks)
    setfield!(aes, Symbol(stat.out_var, "grid"), grids)
    setfield!(aes, Symbol(stat.out_var, "tick_label"), labeler)
    setfield!(aes, Symbol(stat.out_var, "tickvisible"), tickvisible)
    setfield!(aes, Symbol(stat.out_var, "tickscale"), tickscale)

    viewmin_var = Symbol(stat.out_var, "viewmin")
    if getfield(aes, viewmin_var) === nothing ||
       getfield(aes, viewmin_var) > viewmin
        setfield!(aes, viewmin_var, viewmin)
    end

    viewmax_var = Symbol(stat.out_var, "viewmax")
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


function input_aesthetics(stat::BoxplotStatistic)
    return [:x, :y]
end


function output_aesthetics(stat::BoxplotStatistic)
    return [:x, :middle, :lower_hinge, :upper_hinge, :lower_fence, :upper_fence, :outliers]
end


const boxplot = BoxplotStatistic


function apply_statistic(stat::BoxplotStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    if aes.y === nothing
        Gadfly.assert_aesthetics_defined("BoxplotStatistic", aes,
            :x, :lower_hinge, :upper_hinge, :lower_fence, :upper_fence)

        aes_color = aes.color === nothing ? [nothing] : aes.color
        groups = Any[]
        for (x, c) in zip(aes.x, cycle(aes_color))
            push!(groups, (x, c))
        end

        if !is(aes.color, nothing)
            aes.color = PooledDataArray([c for (x, c) in groups],
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

    if length(aes.x) > 1 && (haskey(scales, :x) && isa(scales[:x], Scale.ContinuousScale))
        xmin, xmax = minimum(aes.x), maximum(aes.x)
        minspan = minimum([xj - xi for (xi, xj) in zip(aes.x[1:end-1], aes.x[2:end])])

        xviewmin = xmin - minspan / 2
        xviewmax = xmax + minspan / 2

        if aes.xviewmin === nothing || aes.xviewmin > xviewmin
            aes.xviewmin = xviewmin
        end

        if aes.xviewmax === nothing || aes.xviewmax < xviewmax
            aes.xviewmax = xviewmax
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


function input_aesthetics(::SmoothStatistic)
    return [:x, :y]
end


function output_aesthetics(::SmoothStatistic)
    return [:x, :y]
end


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
            aes.y = Loess.predict(loess(xs, ys, span=stat.smoothing), aes.x)
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
                smoothys = Loess.predict(loess(xs, ys, span=stat.smoothing), steps)
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

    counts = Dict{(@compat Tuple{Int, Int}), Int}()
    for (x, y) in zip(aes.x, aes.y)
        h = convert(HexagonOffsetOddR, cube_round(x - xmin + xspan/2,
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

    aes.color_key_title = "Count"

    Scale.apply_scale(color_scale, [aes], data)
end


function default_scales(::HexBinStatistic, t::Gadfly.Theme)
    return [t.continuous_color_scale]
end


immutable StepStatistic <: Gadfly.StatisticElement
    direction::Symbol

    function StepStatistic(; direction::Symbol=:hv)
        return new(direction)
    end
end

const step = StepStatistic


function input_aesthetics(::StepStatistic)
    return [:x, :y]
end


function output_aesthetics(::StepStatistic)
    return [:x, :y]
end


function apply_statistic(stat::StepStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("StepStatistic", aes, :x)
    Gadfly.assert_aesthetics_defined("StepStatistic", aes, :y)
    Gadfly.assert_aesthetics_equal_length("StepStatistic", aes, :x, :y)

    p = sortperm(aes.x, alg=MergeSort)
    permute!(aes.x, p)
    permute!(aes.y, p)
    aes.group != nothing && permute!(aes.group, p)
    aes.color != nothing && permute!(aes.color, p)

    if aes.group != nothing
        Gadfly.assert_aesthetics_equal_length("StepStatistic", aes, :x, :group)
        permute!(aes.x, p)
        permute!(aes.y, p)
        permute!(aes.group, p)
        aes.color != nothing && permute!(aes.color, p)
    end

    if aes.color != nothing
        Gadfly.assert_aesthetics_equal_length("StepStatistic", aes, :x, :color)
        # TODO: use this when we switch to 0.4
        # sortperm!(p, aes.color, alg=MergeSort, lt=Gadfly.color_isless)
        p = sortperm(aes.color, alg=MergeSort, lt=Gadfly.color_isless)
        permute!(aes.x, p)
        permute!(aes.y, p)
        permute!(aes.color, p)
        aes.group != nothing && permute!(aes.group, p)
    end

    x_step = Array(eltype(aes.x), 0)
    y_step = Array(eltype(aes.y), 0)
    color_step = aes.color == nothing ? nothing : Array(eltype(aes.color), 0)
    group_step = aes.group == nothing ? nothing : Array(eltype(aes.group), 0)

    i = 1
    i_offset = 1
    while true
        u = i_offset + div(i - 1, 2) + (isodd(i) || stat.direction != :hv ? 0 : 1)
        v = i_offset + div(i - 1, 2) + (isodd(i) || stat.direction != :vh ? 0 : 1)

        if u > length(aes.x) || v > length(aes.y)
            break
        end

        if (aes.color != nothing &&
             (aes.color[u] != aes.color[i_offset] || aes.color[v] != aes.color[i_offset])) ||
           (aes.group != nothing &&
             (aes.group[u] != aes.color[i_offset] || aes.color[v] != aes.group[i_offset]))
            i_offset = max(u, v)
            i = 1
        else
            push!(x_step, aes.x[u])
            push!(y_step, aes.y[v])
            aes.color != nothing && push!(color_step, aes.color[i_offset])
            aes.group != nothing && push!(group_step, aes.group[i_offset])
            i += 1
        end
    end

    aes.x = x_step
    aes.y = y_step
    aes.color = color_step
    aes.group = group_step
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


function input_aesthetics(::FunctionStatistic)
    return [:y, :xmin, :xmax]
end


function output_aesthetics(::FunctionStatistic)
    return [:x, :y, :group]
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
        data.color = Array(AbstractString, length(aes.y) * stat.num_samples)
        groups = DataArray(Int, length(aes.y) * stat.num_samples)
        for i in 1:length(aes.y)
            fname = "f<sub>$(i)</sub>"
            data.color[1+(i-1)*stat.num_samples:i*stat.num_samples] = fname
            groups[1+(i-1)*stat.num_samples:i*stat.num_samples] = i
        end
        Scale.apply_scale(scales[:color], [aes], data)
        aes.group = PooledDataArray(groups)
    end

    data = Gadfly.Data()
    data.y = ys
    Scale.apply_scale(scales[:y], [aes], data)
end


immutable ContourStatistic <: Gadfly.StatisticElement
    levels
    samples::Int

    function ContourStatistic(; levels=15, samples=150)
        new(levels, samples)
    end
end


function input_aesthetics(::ContourStatistic)
    return [:z, :xmin, :xmax, :ymin, :ymax]
end


function output_aesthetics(::ContourStatistic)
    return [:x, :y, :color, :group]
end


const contour = ContourStatistic


function default_scales(::ContourStatistic, t::Gadfly.Theme=Gadfly.current_theme())
    return [Gadfly.Scale.z_func(), Gadfly.Scale.x_continuous(),
            Gadfly.Scale.y_continuous(),
            t.continuous_color_scale]
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
            xs = collect(Float64, 1:size(zs)[1])
        end
        if ys == nothing
            ys = collect(Float64, 1:size(zs)[2])
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
    for level in Contour.levels(Contour.contours(xs, ys, zs, stat.levels))
        for line in Contour.lines(level)
            xc, yc = Contour.coordinates(line)
            append!(contour_xs, xc)
            append!(contour_ys, yc)
            for _ in 1:length(xc)
                push!(groups, group)
                push!(levels, Contour.level(level))
            end
            group += 1
        end
    end

    aes.group = groups
    color_scale = get(scales, :color, Gadfly.Scale.color_continuous_gradient())
    Scale.apply_scale(color_scale, [aes], Gadfly.Data(color=levels))
    Scale.apply_scale(scales[:x], [aes],  Gadfly.Data(x=contour_xs))
    Scale.apply_scale(scales[:y], [aes], Gadfly.Data(y=contour_ys))
end


immutable QQStatistic <: Gadfly.StatisticElement
end


function input_aesthetics(::QQStatistic)
    return [:x, :y]
end


function output_aesthetics(::QQStatistic)
    return [:x, :y]
end


const qq = QQStatistic

function default_scales(::QQStatistic)
    return [Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous]
end

function apply_statistic(stat::QQStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Stat.qq", aes, :x, :y)
    Gadfly.assert_aesthetics_undefined("State.qq", aes, :color)

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
    # direct `@compat(Union{NumericalOrCategoricalAesthetic, Distribution})`.
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


immutable ViolinStatistic <: Gadfly.StatisticElement
    # Number of points sampled
    n::Int

    function ViolinStatistic(n=300)
        new(n)
    end
end


function input_aesthetics(::ViolinStatistic)
    return [:x, :y, :width]
end


const violin = ViolinStatistic


function apply_statistic(stat::ViolinStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    if !isa(aes.y[1], Real)
        error("Kernel density estimation only works on Real types.")
    end

    if aes.x === nothing
        y_f64 = collect(Float64, aes.y)
        window = stat.n > 1 ? KernelDensity.default_bandwidth(y_f64) : 0.1
        f = KernelDensity.kde(y_f64, bandwidth=window, npoints=stat.n)
        aes.y = collect(Float64, f.x)
        aes.width = f.density
    else
        grouped_y = DefaultDict(eltype(aes.x), Vector{Float64}, () -> Float64[])
        for (x, y) in zip(cycle(aes.x), aes.y)
            push!(grouped_y[x], y)
        end

        aes.x     = Array(Float64, 0)
        aes.y     = Array(Float64, 0)
        aes.width = Array(Float64, 0)

        for (x, ys) in grouped_y
            window = stat.n > 1 ? KernelDensity.default_bandwidth(ys) : 0.1
            f = KernelDensity.kde(ys, bandwidth=window, npoints=stat.n)
            append!(aes.y, f.x)
            append!(aes.width, f.density)
            for _ in 1:length(f.x)
                push!(aes.x, x)
            end
        end
    end

    pad = 0.1
    maxwidth = maximum(aes.width)
    broadcast!(*, aes.width, aes.width, 1 - pad)
    broadcast!(/, aes.width, aes.width, maxwidth)
end


immutable JitterStatistic <: Gadfly.StatisticElement
    vars::Vector{Symbol}
    range::Float64
    seed::UInt32

    function JitterStatistic(vars::Vector{Symbol}; range=0.8, seed=0x0af5a1f7)
        return new(vars, range, seed)
    end
end


x_jitter(; range=0.8, seed=0x0af5a1f7) = JitterStatistic([:x], range=range, seed=seed)
y_jitter(; range=0.8, seed=0x0af5a1f7) = JitterStatistic([:y], range=range, seed=seed)


function input_aesthetics(stat::JitterStatistic)
    return stat.vars
end


function output_aesthetics(stat::JitterStatistic)
    return stat.vars
end


function minimum_span(vars::Vector{Symbol}, aes::Gadfly.Aesthetics)
    span = nothing
    for var in vars
        data = getfield(aes, var)
        if length(data) < 2
            continue
        end
        dataspan = data[2] - data[1]
        T = eltype(data)
        z = convert(T, zero(T))
        sorteddata = sort(data)
        for (u, v) in partition(sorteddata, 2, 1)
            δ = v - u
            if δ != z && (δ < dataspan || dataspan == z)
                dataspan = δ
            end
        end

        if span == nothing || (dataspan != nothing && dataspan < span)
            span = dataspan
        end
    end

    return span
end


function apply_statistic(stat::JitterStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    span = minimum_span(stat.vars, aes)
    if span == nothing
        return
    end

    rng = MersenneTwister(stat.seed)
    for var in stat.vars
        data = getfield(aes, var)
        outdata = Array(Float64, size(data))
        broadcast!(+, outdata, data, stat.range * (rand(rng, length(data)) - 0.5) .* span)
        setfield!(aes, var, outdata)
    end
end



# Bin mean returns the mean of x and y in n bins of x


immutable BinMeanStatistic <: Gadfly.StatisticElement
    n::Int
    function BinMeanStatistic(;n=20)
        new(n)
    end
end


const binmean = BinMeanStatistic


function input_aesthetics(::BinMeanStatistic)
    return [:x, :y]
end


function output_aesthetics(::BinMeanStatistic)
    return [:x, :y]
end


function apply_statistic(stat::BinMeanStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Stat.binmean", aes, :x, :y)

    breaks = quantile(aes.x, collect(1:stat.n)/stat.n)

    Tx = eltype(aes.x)
    Ty = eltype(aes.y)

    if aes.color === nothing
        (aes.x, aes.y) = mean_by_group(aes.x, aes.y, breaks)
    else
        groups = Dict()
        for (x, y, c) in zip(aes.x, aes.y, cycle(aes.color))
            if !haskey(groups, c)
                xs = append!(Tx[], collect(Tx, aes.x))
                ys = append!(Ty[], collect(Ty, aes.y))
                groups[c] = Array[xs, ys]
            else
                push!(groups[c][1], x)
                push!(groups[c][2], y)
            end
        end
        colors = Array(RGB{Float32}, 0)
        aes.x = Array(Tx, 0)
        aes.y = Array(Ty, 0)
        for (c, v) in groups
            (fx, fy) = mean_by_group(v[1], v[2], breaks)
            append!(aes.x, fx)
            append!(aes.y, fy)
            for _ in 1:length(fx)
                push!(colors, c)
            end
        end
        aes.color = PooledDataArray(colors)
    end
end

function mean_by_group{Tx, Ty}(x::Vector{Tx}, y::Vector{Ty}, breaks::Vector{Float64})
    count = zeros(Int64, length(breaks))
    totalx = zeros(Tx, length(breaks))
    totaly = zeros(Ty, length(breaks))
    for i in 1:length(x)
        refs = searchsortedfirst(breaks, x[i])
        count[refs] += 1
        totalx[refs] += x[i]
        totaly[refs] += y[i]
    end
    subset = count .> 0
    count = count[subset]
    return (totalx[subset] ./ count, totaly[subset] ./ count)
end


immutable EnumerateStatistic <: Gadfly.StatisticElement
    var::Symbol
end


function input_aesthetics(stat::EnumerateStatistic)
    return [stat.var]
end


function output_aesthetics(stat::EnumerateStatistic)
    return [stat.var == :x ? :y : :x]
end


function default_scales(stat::EnumerateStatistic)
    if stat.var == :y
        return [Gadfly.Scale.y_continuous()]
    elseif stat.var == :x
        return [Gadfly.Scale.x_continuous()]
    else
        return Gadfly.ScaleElement[]
    end
end


const x_enumerate = EnumerateStatistic(:x)
const y_enumerate = EnumerateStatistic(:y)


function apply_statistic(stat::EnumerateStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    has_x = aes.x != nothing
    has_y = aes.y != nothing

    if stat.var == :x && !has_x && has_y
        aes.x = collect(1:length(aes.y))
    elseif stat.var == :y && !has_y && has_x
        aes.y = collect(1:length(aes.x))
    end
end


end # module Stat
