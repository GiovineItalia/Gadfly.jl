module Stat

import Gadfly
import Contour
using Colors
using Compat
using Compose
using DataStructures
using Dates
using Distributions
using Hexagons
using Loess
using CoupledFields # It is registered in METADATA.jl
using IndirectArrays
using Statistics
using LinearAlgebra
using Random

import Gadfly: Scale, Coord, input_aesthetics, output_aesthetics,
               default_scales, isconcrete, setfield!, discretize_make_ia, aes2str
import KernelDensity
# import Distributions: Uniform, Distribution, qqbuild
import IterTools: distinct
import Compat.Iterators: cycle, product

include("bincount.jl")


function apply_statistics(stats::Vector{Gadfly.StatisticElement},
                          scales::Dict{Symbol, Gadfly.ScaleElement},
                          coord::Gadfly.CoordinateElement,
                          aes::Gadfly.Aesthetics)
    for stat in stats
        apply_statistic(stat, scales, coord, aes)
    end
    nothing
end

struct Nil <: Gadfly.StatisticElement end

"""
    Stat.Nil
"""
const nil = Nil

struct Identity <: Gadfly.StatisticElement end

apply_statistic(stat::Identity,
                scales::Dict{Symbol, Gadfly.ScaleElement},
                coord::Gadfly.CoordinateElement,
                aes::Gadfly.Aesthetics) = nothing

"""
    Stat.identity
"""
const identity = Identity


# Determine bounds of bars positioned at the given values.
function barminmax(vals, iscontinuous::Bool)
    minvalue, maxvalue = extrema(vals)
    span_type = typeof((maxvalue - minvalue) / 1.0)
    barspan = one(span_type)

    if iscontinuous && length(vals) > 1
        sorted_vals = sort(vals)
        T = typeof(sorted_vals[2] - sorted_vals[1])
        z = zero(T)
        minspan = z
        for i in 2:length(vals)
            span = sorted_vals[i] - sorted_vals[i-1]
            if span > z && (span < minspan || minspan == z)
                minspan = span
            end
        end
        barspan = minspan
    end
    position_type = promote_type(typeof(barspan/2.0), eltype(vals))
    minvals = Array{position_type}(undef, length(vals))
    maxvals = Array{position_type}(undef, length(vals))

    for (i, x) in enumerate(vals)
        minvals[i] = x - barspan/2.0
        maxvals[i] = x + barspan/2.0
    end

    return minvals, maxvals
end


struct RectbinStatistic <: Gadfly.StatisticElement end

input_aesthetics(stat::RectbinStatistic) = [:x, :y]
output_aesthetics(stat::RectbinStatistic) = [:xmin, :xmax, :ymin, :ymax]

"""
    Stat.rectbin

Transform $(aes2str(input_aesthetics(rectbin()))) into
$(aes2str(output_aesthetics(rectbin()))).
"""
const rectbin = RectbinStatistic

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
        aes.pad_categorical_x = false
    end
    if !isycontinuous
        aes.pad_categorical_y = false
    end
end


struct BarStatistic <: Gadfly.StatisticElement
    position::Symbol # :dodge or :stack
    orientation::Symbol # :horizontal or :vertical
end
BarStatistic(; position=:stack, orientation=:vertical) = BarStatistic(position, orientation)

input_aesthetics(stat::BarStatistic) = stat.orientation == :vertical ? [:x] : [:y]
output_aesthetics(stat::BarStatistic) =
    stat.orientation == :vertical ? [:xmin, :xmax] : [:ymin, :ymax]
default_scales(stat::BarStatistic) = stat.orientation == :vertical ?
        [Gadfly.Scale.y_continuous()] : [Gadfly.Scale.x_continuous()]

"""
    Stat.bar[(; position=:stack, orientation=:vertical)]

Transform $(aes2str(input_aesthetics(bar()))) into
$(aes2str(output_aesthetics(bar()))).  Used by [`Geom.bar`](@ref Gadfly.Geom.bar).
"""
const bar = BarStatistic

function apply_statistic(stat::BarStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    if stat.orientation == :horizontal
        in(:y, Gadfly.defined_aesthetics(aes)) || return
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
        in(:x, Gadfly.defined_aesthetics(aes)) || return
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

    vals = getfield(aes, var)
    if isempty(vals)
      setfield!(aes, minvar, Float64[1.0])
      setfield!(aes, maxvar, Float64[1.0])
      setfield!(aes, var, Float64[1.0])
      setfield!(aes, othervar, Float64[0.0])
      return
    end

    iscontinuous = haskey(scales, var) && isa(scales[var], Scale.ContinuousScale)

    if getfield(aes, minvar) == nothing || getfield(aes, maxvar) == nothing
        minvals, maxvals = barminmax(vals, iscontinuous)

        setfield!(aes, minvar, minvals)
        setfield!(aes, maxvar, maxvals)
    end

    z = zero(eltype(getfield(aes, othervar)))
    if getfield(aes, viewminvar) == nothing && z < minimum(getfield(aes, othervar))
        setfield!(aes, viewminvar, z)
    elseif getfield(aes, viewmaxvar) == nothing && z > maximum(getfield(aes, othervar))
        setfield!(aes, viewmaxvar, z)
    end

    if stat.position == :stack && aes.color !== nothing
        groups = Dict{Any,Float64}()
        for (x, y) in zip(getfield(aes, othervar), vals)
            Gadfly.isconcrete(x) || continue

            if !haskey(groups, y)
                groups[y] = Float64(x)
            else
                groups[y] += Float64(x)
            end
        end

        viewmin, viewmax = extrema(values(groups))
        aes_viewminvar = getfield(aes, viewminvar)
        if aes_viewminvar === nothing || aes_viewminvar > viewmin
            setfield!(aes, viewminvar, viewmin)
        end
        aes_viewmaxvar = getfield(aes, viewmaxvar)
        if aes_viewmaxvar === nothing || aes_viewmaxvar < viewmax
            setfield!(aes, viewmaxvar, viewmax)
        end
    end

    if !iscontinuous
        if stat.orientation == :horizontal
            aes.pad_categorical_y = false
        else
            aes.pad_categorical_x = false
        end
    end
end


struct HistogramStatistic <: Gadfly.StatisticElement
    minbincount::Int
    maxbincount::Int
    position::Symbol # :dodge or :stack
    orientation::Symbol
    density::Bool
    limits::NamedTuple
end

function HistogramStatistic(; bincount=nothing,
                              minbincount=3,
                              maxbincount=150,
                              position=:stack,
                              orientation=:vertical,
                              density=false,
                              limits=NamedTuple())
    if bincount != nothing
        HistogramStatistic(bincount, bincount, position, orientation, density, limits)
    else
        HistogramStatistic(minbincount, maxbincount, position, orientation, density, limits)
    end
end

input_aesthetics(stat::HistogramStatistic) = stat.orientation == :vertical ? [:x] : [:y]  ### and :color
output_aesthetics(stat::HistogramStatistic) =
    stat.orientation == :vertical ? [:x, :y, :xmin, :xmax] : [:y, :x, :ymin, :ymax]
default_scales(stat::HistogramStatistic) = stat.orientation == :vertical ?
        [Gadfly.Scale.y_continuous()] : [Gadfly.Scale.x_continuous()]

"""
    Stat.histogram[(; bincount=nothing, minbincount=3, maxbincount=150,
            position=:stack, orientation=:vertical, density=false, limits=NamedTuple())]

Transform $(aes2str(input_aesthetics(histogram()))) into
$(aes2str(output_aesthetics(histogram()))), optionally grouping by `color`.
Exchange y for x when `orientation` is `:horizontal`.  `bincount` specifies the
number of bins to use.  If set to `nothing`, an optimization method is used to
determine a reasonable value which uses `minbincount` and `maxbincount` to set
the lower and upper limits.  If `density` is `true`, normalize the counts by
their total. `limits` is a `NamedTuple` that sets the limits of the histogram `(min= , max= )`: 
`min` or `max` or both can be set.
"""
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

    vals = getfield(aes, var)
    stat.minbincount > stat.maxbincount && error("Histogram minbincount > maxbincount")

    if isempty(getfield(aes, var))
        setfield!(aes, minvar, Float64[1.0])
        setfield!(aes, maxvar, Float64[1.0])
        setfield!(aes, var, Float64[1.0])
        setfield!(aes, othervar, Float64[0.0])
        return
    end

    if haskey(scales, var) && isa(scales[var], Scale.DiscreteScale)
        isdiscrete = true
        x_min, x_max = extrema(vals)
        d = x_max - x_min + 1
        bincounts = zeros(Int, d)
        for x in vals
            bincounts[x - x_min + 1] += 1
        end
        x_min -= 0.5 # adjust the left side of the bar
        binwidth = 1.0
    else
        lims = fieldnames(typeof(stat.limits))
        x_min = in(:min, lims) ? stat.limits.min : Gadfly.concrete_minimum(vals)

        isdiscrete = false
        if estimate_distinct_proportion(vals) <= 0.9
            value_set = sort!(collect(Set(vals[Bool[Gadfly.isconcrete(v) for v in vals]])))
            d, bincounts, xmax = choose_bin_count_1d_discrete(vals, value_set, stat.minbincount, stat.maxbincount)
        else
            d, bincounts, xmax = choose_bin_count_1d(vals, stat.minbincount, stat.maxbincount)
        end
        x_max = in(:max, lims) ? stat.limits.max : xmax

        binwidth = (x_max - x_min) / d
    end

    stat.density && (bincounts = bincounts ./ (sum(bincounts) * binwidth))

    if aes.color === nothing
        T = typeof(x_min + 1*binwidth)
        setfield!(aes, othervar, Array{Float64}(undef, d))
        setfield!(aes, minvar, Array{T}(undef, d))
        setfield!(aes, maxvar, Array{T}(undef, d))
        setfield!(aes, var, Array{T}(undef, d))
        for j in 1:d
            getfield(aes, minvar)[j] = x_min + (j - 1) * binwidth
            getfield(aes, maxvar)[j] = x_min + j * binwidth
            getfield(aes, var)[j] = x_min + (j - 0.5) * binwidth
            getfield(aes, othervar)[j] = bincounts[j]
        end
    else
        CT, VT = eltype(aes.color), eltype(vals)
        groups = Dict{CT,Vector{VT}}(c=>VT[] for c in unique(aes.color))
        for (x, c) in zip(vals, cycle(aes.color))
            Gadfly.isconcrete(x) && push!(groups[c], x)
        end
        T = typeof(x_min + 1*binwidth)
        setfield!(aes, minvar, Array{T}(undef, d * length(groups)))
        setfield!(aes, maxvar, Array{T}(undef, d * length(groups)))
        setfield!(aes, var, Array{T}(undef, d * length(groups)))
        setfield!(aes, othervar, Array{Float64}(undef, d * length(groups)))
        colors = Array{RGB{Float32}}(undef, d * length(groups))

        x_span = x_max - x_min
        stack_height = zeros(Int, d)
        for (i, (c, xs)) in enumerate(groups)
            fill!(bincounts, 0)
            for x in xs
                if isdiscrete
                    bincounts[round(Int,x)] += 1
                else
                    bin = max(1, min(d, (ceil(Int, (x - x_min) / binwidth))))
                    bincounts[bin] += 1
                end
            end

            if stat.density
                binwidth = x_span / d
                bincounts = bincounts ./ (sum(bincounts) * binwidth)
            end

            stack_height += bincounts[1:d]

            for j in 1:d
                idx = (i-1)*d + j
                getfield(aes, var)[idx] = isdiscrete ? j : x_min + (j - 0.5) * binwidth
                getfield(aes, minvar)[idx] = x_min + (j - 1) * binwidth
                getfield(aes, maxvar)[idx] = x_min + j * binwidth
                getfield(aes, othervar)[idx] = bincounts[j]
                colors[idx] = c
            end
        end

        if stat.position == :stack
            viewmax = Float64(maximum(stack_height))
            aes_viewmax = getfield(aes, viewmaxvar)
            if aes_viewmax === nothing || aes_viewmax < viewmax
                setfield!(aes, viewmaxvar, viewmax)
            end
        end

        aes.color = discretize_make_ia(colors)
    end

    getfield(aes, viewminvar) === nothing && setfield!(aes, viewminvar, 0.0)

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

                naive_stackheight == 0 && continue

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


struct Density2DStatistic <: Gadfly.StatisticElement
    n::Tuple{Int,Int} # Number of points sampled
    bw::Tuple{Real,Real} # Bandwidth used for the kernel density estimation
    levels::Union{Int,Vector,Function}
end
Density2DStatistic(; n=(256,256), bandwidth=(-Inf,-Inf), levels=15) =
      Density2DStatistic(n, bandwidth, levels)

input_aesthetics(stat::Density2DStatistic) = [:x, :y]
output_aesthetics(stat::Density2DStatistic) = [:x, :y, :z]
default_scales(::Density2DStatistic) = [Gadfly.Scale.y_continuous()]

"""
    Stat.density2d[(; n=(256,256), bandwidth=(-Inf,-Inf), levels=15)]

Estimate the density of $(aes2str(input_aesthetics(density2d()))) at `n` points
and put the results into $(aes2str(output_aesthetics(density2d()))).  Smoothing
is controlled by `bandwidth`.  Calls [`Stat.contour`](@ref) to compute the
`levels`.  Used by [`Geom.density2d`](@ref Gadfly.Geom.density2d).
"""
const density2d = Density2DStatistic

function apply_statistic(stat::Density2DStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Density2DStatistic", aes, :x, :y)

    window = (stat.bw[1] <= 0.0 ? KernelDensity.default_bandwidth(aes.x) : stat.bw[1],
              stat.bw[2] <= 0.0 ? KernelDensity.default_bandwidth(aes.y) : stat.bw[2])
    k = KernelDensity.kde((aes.x,aes.y), bandwidth=window, npoints=stat.n)
    aes.z = k.density
    aes.x = collect(k.x)
    aes.y = collect(k.y)
    apply_statistic(ContourStatistic(levels=stat.levels), scales, coord, aes)
end


struct DensityStatistic <: Gadfly.StatisticElement
    # Number of points sampled
    n::Int
    # Bandwidth used for the kernel density estimation
    bw::Real
end
DensityStatistic(; n=256, bandwidth=-Inf) = DensityStatistic(n, bandwidth)

input_aesthetics(stat::DensityStatistic) = [:x, :color]
output_aesthetics(stat::DensityStatistic) = [:x, :y, :color]
default_scales(::DensityStatistic) = [Gadfly.Scale.y_continuous()]

"""
    Stat.density[(; n=256, bandwidth=-Inf)]

Estimate the density of `x` at `n` points, and put the result in `x` and `y`.
Smoothing is controlled by `bandwidth`.  Used by [`Geom.density`](@ref Gadfly.Geom.density).
"""
const density = DensityStatistic

function apply_statistic(stat::DensityStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("DensityStatistic", aes, :x)

    if aes.color === nothing
        isa(aes.x[1], Real) || error("Kernel density estimation only works on Real types.")

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

        colors = Array{RGB{Float32}}(undef, 0)
        aes.x = Array{Float64}(undef, 0)
        aes.y = Array{Float64}(undef, 0)
        for (c, xs) in groups
            window = stat.bw <= 0.0 ? KernelDensity.default_bandwidth(xs) : stat.bw
            f = KernelDensity.kde(xs, bandwidth=window, npoints=stat.n)
            append!(aes.x, f.x)
            append!(aes.y, f.density)
            for _ in 1:length(f.x)
                push!(colors, c)
            end
        end
        aes.color = discretize_make_ia(colors)
    end
    aes.y_label = Gadfly.Scale.identity_formatter
end


struct Histogram2DStatistic <: Gadfly.StatisticElement
    xminbincount::Int
    xmaxbincount::Int
    yminbincount::Int
    ymaxbincount::Int
end

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

    Histogram2DStatistic(xminbincount, xmaxbincount, yminbincount, ymaxbincount)
end

input_aesthetics(stat::Histogram2DStatistic) = [:x, :y]
output_aesthetics(stat::Histogram2DStatistic) = [:xmin, :ymax, :ymin, :ymax, :color]
default_scales(::Histogram2DStatistic, t::Gadfly.Theme=Gadfly.current_theme()) =
    [t.continuous_color_scale]

"""
    Stat.histogram2d[(; xbincount=nothing, xminbincount=3, xmaxbincount=150,
                        ybincount=nothing, yminbincount=3, ymaxbincount=150)]

Bin the points in $(aes2str(input_aesthetics(histogram2d()))) into rectangles
in $(aes2str(output_aesthetics(histogram2d()))).  `xbincount` and `ybincount`
manually fix the number of bins.  If set to `nothing`, an optimization method
is used to determine a reasonable value which uses `xminbincount`,
`xmaxbincount`, `yminbincount` and `ymaxbincount` to set the lower and upper
limits.
"""
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

    wx = (x_max==x_min) ? 1.0 : (x_max - x_min) / dx
    wy = (y_max==y_min) ? 1.0 : (y_max - y_min) / dy
    !x_categorial && (x_max==x_min) && (x_min-=0.5)
    !y_categorial && (y_max==y_min) && (y_min-=0.5)
                                        
    n = 0
    for cnt in bincounts
        if cnt > 0
            n += 1
        end
    end

    if x_categorial
        aes.x = Array{Int64}(undef, n)
    else
        aes.xmin = Array{Float64}(undef, n)
        aes.xmax = Array{Float64}(undef, n)
    end

    if y_categorial
        aes.y = Array{Int64}(undef, n)
    else
        aes.ymin = Array{Float64}(undef, n)
        aes.ymax = Array{Float64}(undef, n)
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

    haskey(scales, :color) || error("Histogram2DStatistic requires a color scale.")
    color_scale = scales[:color]
    typeof(color_scale) <: Scale.ContinuousColorScale ||
            error("Histogram2DStatistic requires a continuous color scale.")

    aes.color_key_title = "Count"

    data = Gadfly.Data()
    data.color = Array{Int}(undef, n)
    k = 1
    for cnt in transpose(bincounts)
        if cnt > 0
            data.color[k] = cnt
            k += 1
        end
    end

    if x_categorial
        aes.xmin, aes.xmax = barminmax(aes.x, false)
        aes.x = discretize_make_ia(aes.x)
        aes.pad_categorical_x = false
    end

    if y_categorial
        aes.ymin, aes.ymax = barminmax(aes.y, false)
        aes.y = discretize_make_ia(aes.y)
        aes.pad_categorical_y = false
    end

    Scale.apply_scale(color_scale, [aes], data)
    nothing
end

# Find reasonable places to put tick marks and grid lines.
struct TickStatistic <: Gadfly.StatisticElement
    axis::AbstractString

    granularity_weight::Float64
    simplicity_weight::Float64
    coverage_weight::Float64
    niceness_weight::Float64

    # fixed ticks, or nothing
    ticks::Union{Symbol, AbstractArray}
end

@deprecate xticks(ticks) xticks(ticks=ticks)

### add hinges and fences to y-axis?
input_aesthetics(stat::TickStatistic) = stat.axis=="x" ? [:x, :xmin, :xmax, :xintercept] :
    [:y, :ymin, :ymax, :yintercept, :middle, :lower_hinge, :upper_hinge, :lower_fence, :upper_fence]
output_aesthetics(stat::TickStatistic) = stat.axis=="x" ? [:xtick, :xgrid] : [:ytick, :ygrid]

xy_ticks(var,in_aess,out_aess) = """
    Stat.$(var)ticks[(; ticks=:auto, granularity_weight=1/4, simplicity_weight=1/6,
                coverage_weight=1/3, niceness_weight=1/4)]

Compute an appealing set of $(var)-ticks that encompass the data by
transforming $(in_aess) into $(out_aess).  `ticks` is a vector of desired
values, or `:auto` to indicate they should be computed.  the importance of
having a reasonable number of ticks is specified with `granularity_weight`; of
including zero with `simplicity_weight`; of tightly fitting the span of the
data with `coverage_weight`; and of having a nice numbering with
`niceness_weight`.
"""

# can be put on two lines with julia 0.7
@doc xy_ticks("x",aes2str(input_aesthetics(xticks())), aes2str(output_aesthetics(xticks()))) xticks(; ticks=:auto,
         granularity_weight=1/4,
         simplicity_weight=1/6,
         coverage_weight=1/3,
         niceness_weight=1/4) = 
    TickStatistic("x",
              granularity_weight, simplicity_weight, coverage_weight, niceness_weight, ticks)

@deprecate yticks(ticks) yticks(ticks=ticks)

@doc xy_ticks("y",aes2str(input_aesthetics(yticks())), aes2str(output_aesthetics(yticks()))) yticks(; ticks=:auto,
         granularity_weight=1/4,
         simplicity_weight=1/6,
         coverage_weight=1/3,
         niceness_weight=1/4) =
    TickStatistic("y",
        granularity_weight, simplicity_weight, coverage_weight, niceness_weight, ticks)

function apply_statistic(stat::TickStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    in_vars = input_aesthetics(stat)
    isa(stat.ticks, Symbol) && stat.ticks != :auto &&
            error("Invalid value $(stat.ticks) for ticks parameter.")

    isa(coord, Coord.SubplotGrid) &&
            error("TickStatistic cannot be applied to subplot coordinates.")

    # don't clobber existing ticks
    getfield(aes, Symbol(stat.axis, "tick")) == nothing || return

    in_group_var = Symbol(stat.axis, "group")
    minval, maxval = nothing, nothing
    in_vals = Any[]
    categorical = (:x in in_vars && Scale.iscategorical(scales, :x)) ||
                  (:y in in_vars && Scale.iscategorical(scales, :y))

    for var in in_vars
        categorical && !in(var,[:x,:y]) && continue
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

            if stat.axis == "x"
                dsize = aes.xsize === nothing ? [nothing] : aes.xsize
            elseif stat.axis == "y"
                dsize = aes.ysize === nothing ? [nothing] : aes.ysize
            else
                dsize = [nothing]
            end

            size = aes.size === nothing ? [nothing] : aes.size

            minval, maxval = apply_statistic_typed(minval, maxval, vals, size, dsize)
            push!(in_vals, vals)
        end
    end

    isempty(in_vals) && return

    in_vals = Iterators.flatten(in_vals)

    # consider forced tick marks
    if stat.ticks != :auto
        minval = min(minval, minimum(stat.ticks))
        maxval = max(maxval, maximum(stat.ticks))
    end

    # TODO: handle the outliers aesthetic

    n = Gadfly.concrete_length(in_vals)

    # check the x/yviewmin/max pesudo-aesthetics
    if stat.axis == "x"
        if aes.xviewmin != nothing
            minval = min(minval, aes.xviewmin)
        end
        if aes.xviewmax != nothing
            maxval = max(maxval, aes.xviewmax)
        end
    elseif stat.axis == "y"
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
        if stat.axis == "x"
            if coord.xmin !== nothing
                minval = coord.xmin
                strict_span = true
            end
            if coord.xmax !== nothing
                maxval = coord.xmax
                strict_span = true
            end
        elseif stat.axis == "y"
            if coord.ymin !== nothing
                minval = coord.ymin
                strict_span = true
            end
            if coord.ymax !== nothing
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
        for val in in_vals
            val>0 && push!(ticks, round(Int, val))
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

        ticks, viewmin, viewmax = Gadfly.optimize_ticks(minval, maxval, extend_ticks=true,
                granularity_weight=stat.granularity_weight,
                simplicity_weight=stat.simplicity_weight,
                coverage_weight=stat.coverage_weight,
                niceness_weight=stat.niceness_weight,
                strict_span=strict_span)
        grids = ticks
        multiticks = Gadfly.multilevel_ticks(viewmin - (viewmax - viewmin),
                                             viewmax + (viewmax - viewmin))
        tickcount = length(ticks) + sum([length(ts) for ts in values(multiticks)])
        tickvisible = Array{Bool}(undef, tickcount)
        tickscale = Array{Float64}(undef, tickcount)
        i = 1
        for t in ticks
            tickscale[i] = 1.0
            tickvisible[i] = viewmin <= t <= viewmax
            i += 1
        end

        for (scale, ts) in multiticks, t in ts
            push!(ticks, t)
            tickvisible[i] = false
            tickscale[i] = scale
            i += 1
        end
    end

    # We use the first label function we find for any of the aesthetics. I'm not
    # positive this is the right thing to do, or would would be.
    labeler = getfield(aes, Symbol(stat.axis, "_label"))

    setfield!(aes, Symbol(stat.axis, "tick"), ticks)
    setfield!(aes, Symbol(stat.axis, "grid"), grids)
    setfield!(aes, Symbol(stat.axis, "tick_label"), labeler)
    setfield!(aes, Symbol(stat.axis, "tickvisible"), tickvisible)
    setfield!(aes, Symbol(stat.axis, "tickscale"), tickscale)

    viewmin_var = Symbol(stat.axis, "viewmin")
    if getfield(aes, viewmin_var) === nothing || getfield(aes, viewmin_var) > viewmin
        setfield!(aes, viewmin_var, viewmin)
    end

    viewmax_var = Symbol(stat.axis, "viewmax")
    if getfield(aes, viewmax_var) === nothing || getfield(aes, viewmax_var) < viewmax
        setfield!(aes, viewmax_var, viewmax)
    end

    nothing
end

function apply_statistic_typed(minval::T, maxval::T, vals, size, dsize) where T
#     for (val, s, ds) in zip(vals, cycle(size), cycle(dsize))
    lensize  = length(size)
    lendsize = length(dsize)
    for (i, val) in enumerate(vals)
        (ismissing(val) || !Gadfly.isconcrete(val) || !isfinite(val)) && continue

        s = size[mod1(i, lensize)]
        ds = dsize[mod1(i, lendsize)]

        minval, maxval = minvalmaxval(minval, maxval, convert(T, val), s, ds)
    end
    minval, maxval
end

function minvalmaxval(minval::T, maxval::T, val, s, ds) where T
    if val < minval || !isfinite(minval)
        minval = val
    end

    if val > maxval || !isfinite(maxval)
        maxval = val
    end

    if s != nothing && typeof(s) <: AbstractFloat
        minval = min(minval, val - s)::T
        maxval = max(maxval, val + s)::T
    end

    if ds != nothing
        minval = min(minval, val - ds)::T
        maxval = max(maxval, val + ds)::T
    end

    minval, maxval
end


struct BoxplotStatistic <: Gadfly.StatisticElement
    method::Union{Symbol, Vector}
end
BoxplotStatistic(; method=:tukey) = BoxplotStatistic(method)

input_aesthetics(stat::BoxplotStatistic) = [:x, :y]
output_aesthetics(stat::BoxplotStatistic) =
    [:x, :middle, :lower_hinge, :upper_hinge, :lower_fence, :upper_fence, :outliers]

"""
    Stat.boxplot[(; method=:tukey)]

Transform the $(aes2str(input_aesthetics(boxplot()))) into
$(aes2str(output_aesthetics(boxplot()))).  If `method` is `:tukey` then Tukey's
rule is used (i.e. fences are 1.5 times the inter-quartile range).  Otherwise,
`method` should be a vector of five numbers giving quantiles for lower fence,
lower hinge, middle, upper hinge, and upper fence in that order.  Used by
[`Geom.boxplot`](@ref Gadfly.Geom.boxplot).
"""
const boxplot = BoxplotStatistic

function apply_statistic(stat::BoxplotStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    xflag = aes.x != nothing
    aes_x = (xflag ? eltype(aes.x) : Int)[]
    if xflag
        aes_x = aes.x
    else
        aes_x = ones(Int, length(aes.y))
        aes.x_label = x -> fill("", length(x))
    end
    colorflag = aes.color != nothing
    aes_color =  colorflag ? aes.color : fill(nothing, length(aes_x))
                     
    if aes.y == nothing
        groups = Any[]
        for (x, c) in zip(aes.x, cycle(aes_color))
            push!(groups, (x, c))
        end

        yviewmin, yviewmax = minimum(aes.lower_fence), maximum(aes.upper_fence)
        if aes.outliers !== nothing
            yviewmin = minimum(yviewmin, aes.outliers)
            yviewmax = maximum(yviewmax, aes.outliers)
        end

        if aes.yviewmin === nothing || aes.yviewmin > yviewmin
            aes.yviewmin = yviewmin
        end

        if aes.yviewmax === nothing || aes.yviewmax < yviewmax
            aes.yviewmax = yviewmax
        end
    else
        YT = isempty(aes.y) ? eltype(aes.y) : typeof(aes.y[1] / 1)        
        CT, XT = eltype(aes_color), eltype(aes_x)    
        groups = collect(Tuple{CT, XT}, zip(aes_color, aes_x))
        ug = unique(groups)

        K = Tuple{CT, XT}
        grouped_y = Dict{K, Vector{YT}}(g=>aes.y[groups.==[g]] for g in ug)
 
        m = length(ug)
        aes.x = Vector{XT}(undef, m)
        aes.middle = Vector{YT}(undef, m)
        aes.lower_hinge = Vector{YT}(undef, m)
        aes.upper_hinge = Vector{YT}(undef, m)
        aes.lower_fence = Vector{YT}(undef, m)
        aes.upper_fence = Vector{YT}(undef, m)
        aes.outliers = Vector{YT}[]

        for (i, ((c, x), ys)) in enumerate(grouped_y)
            sort!(ys)

            aes.x[i] = x

            if stat.method == :tukey
                aes.lower_hinge[i], aes.middle[i], aes.upper_hinge[i] = quantile(ys, [0.25, 0.5, 0.75])
                iqr = aes.upper_hinge[i] - aes.lower_hinge[i]

                idx = searchsortedfirst(ys, aes.lower_hinge[i] - 1.5iqr)
                aes.lower_fence[i] = ys[idx]

                idx = searchsortedlast(ys, aes.upper_hinge[i] + 1.5iqr)
                aes.upper_fence[i] = ys[idx]
            elseif isa(stat.method, Vector)
                qs = stat.method
                (length(qs) != 5) && error("Stat.boxplot requires exactly five quantiles.")

                aes.lower_fence[i], aes.lower_hinge[i], aes.middle[i],
                aes.upper_hinge[i], aes.upper_fence[i] = quantile!(ys, qs)
            else
                error("Invalid method specified for State.boxplot")
            end

            push!(aes.outliers, filter(y -> y < aes.lower_fence[i] || y > aes.upper_fence[i], ys))
        end
    end

    if length(aes.x) > 1 && haskey(scales, :x) && isa(scales[:x], Scale.ContinuousScale)
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

    if haskey(scales, :x) && isa(scales[:x], Scale.DiscreteScale)
        aes.xviewmin = minimum(aes.x)-0.5
        aes.xviewmax = maximum(aes.x)+0.5
        aes.pad_categorical_x = false
    end

    isa(aes_x, IndirectArray) && (aes.x = discretize_make_ia(aes.x, aes_x.values))

    colorflag && (aes.color = discretize_make_ia([first(k) for k in keys(grouped_y)], aes.color.values))

    Stat.apply_statistic(Stat.dodge(), scales, coord, aes)

    nothing
end


struct SmoothStatistic <: Gadfly.StatisticElement
    method::Symbol
    smoothing::Float64
    levels::Vector{Float64}
end
SmoothStatistic(; method=:loess, smoothing=0.75, levels=[0.95]) = SmoothStatistic(method, smoothing, levels)

input_aesthetics(::SmoothStatistic) = [:x, :y]
output_aesthetics(::SmoothStatistic) = [:x, :y, :ymin, :ymax]

"""
    Stat.smooth[(; method=:loess, smoothing=0.75, levels=[0.95])]

Transform $(aes2str(input_aesthetics(smooth()))) into
$(aes2str(output_aesthetics(smooth()))).  `method` can either be`:loess` or
`:lm`.  `smoothing` controls the degree of smoothing.  For `:loess`, this is
the span parameter giving the proportion of data used for each local fit where
0.75 is the default. Larger values use more data (less local context), smaller
values use less data (more local context).  `levels` is a vector of quantiles 
at which confidence bands are calculated (currently for `method=:lm` only).
For confidence bands, use `Stat.smooth()` with `Geom.ribbon`.
"""
const smooth = SmoothStatistic

function Stat.apply_statistic(stat::SmoothStatistic,
    scales::Dict{Symbol, Gadfly.ScaleElement},
    coord::Gadfly.CoordinateElement,
    aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Stat.smooth", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Stat.smooth", aes, :x, :y)

    stat.method in [:loess,:lm] ||
    error("The only Stat.smooth methods currently supported are loess and lm.")
   
    local xs, ys, yhat
    try
        xs = Float64.(eltype(aes.x) <: Dates.TimeType ? Dates.value.(aes.x) : aes.x)
        ys = Float64.(eltype(aes.y) <: Dates.TimeType ? Dates.value.(aes.y) : aes.y)
    catch e
        error("Stat.loess and Stat.lm require that x and y be bound to arrays of plain numbers.")
    end

    colorflag = aes.color != nothing
    aes_color =  colorflag ? aes.color : fill(nothing, length(aes.x))

    uc = unique(aes_color)
    groups = Dict(c=>(xs[aes_color.==c], ys[aes_color.==c], aes.x[aes_color.==c]) for c in uc)

    # For aes.y returning a Float is ok if `y` is an Int or a Float
    # There does not seem to be strong demand for other types of `y`
    aes.x = eltype(aes.x)[]
    aes.y = Float64[]
    aes.ymin = Float64[]
    aes.ymax = Float64[]
    colors = eltype(aes_color)[]
    aes.linestyle = String[]

    for (c, (xv, yv, x0)) in groups
        x_min, x_max = minimum(xv), maximum(xv)
        x_min == x_max && error("Stat.smooth requires more than one distinct x value")
        nudge = 1e-5 * (x_max - x_min)

        xsp = copy(xv)
        n = length(xv)
        if stat.method == :loess
            xsp[argmin(xv)] += nudge
            xsp[argmax(xv)] -= nudge
            model = loess(xv, yv, span=stat.smoothing)
            yhat = Loess.predict(model, xsp)
            se = 0.0  # for se and dof, need values from Loess.jl
            dof = 2
        elseif stat.method == :lm
            lmcoeff = hcat(fill!(similar(xv), 1), xv) \ yv
            yhat = lmcoeff[2].*xsp .+ lmcoeff[1]
            se = std(yv.-yhat, mean=0.0)
            dof = n-2
        end
        xi = sqrt.(1/n .+ abs2.(xv.-mean(xv))/sum(abs2,xv.-mean(xv)))

        # Confidence band levels
        level = 0.5*(stat.levels.+1)
        for lvl in level
            qt = quantile(TDist(dof), lvl)
            append!(aes.x, x0)        
            append!(aes.y, yhat)
            append!(colors, fill(c, length(xv)))
            append!(aes.ymin, yhat.-qt*se.*xi)
            append!(aes.ymax, yhat.+qt*se.*xi)
            append!(aes.linestyle, fill("$(lvl)", length(xv)))        
        end
    end

    colorflag && (aes.color = discretize_make_ia(colors))
    linestyle_scale = get(scales, :linestyle, Scale.linestyle_discrete())
    Scale.apply_scale(linestyle_scale, [aes], Gadfly.Data(linestyle = aes.linestyle))
end


struct HexBinStatistic <: Gadfly.StatisticElement
    xbincount::Int
    ybincount::Int
end
HexBinStatistic(; xbincount=50, ybincount=50) = HexBinStatistic(xbincount, ybincount)

input_aesthetics(::HexBinStatistic) = [:x, :y]
output_aesthetics(::HexBinStatistic) = [:x, :y, :xsize, :ysize]
default_scales(::HexBinStatistic, t::Gadfly.Theme) = [t.continuous_color_scale]

"""
    Stat.hexbin[(; xbincount=50, ybincount=50)]

Bin the points in $(aes2str(input_aesthetics(hexbin()))) into hexagons in
$(aes2str(output_aesthetics(hexbin()))).  `xbincount` and `ybincount` manually
fix the number of bins.
"""
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

    counts = Dict{(Tuple{Int, Int}), Int}()
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
    aes.x = Array{Float64}(undef, N)
    aes.y = Array{Float64}(undef, N)
    data = Gadfly.Data()
    data.color = Array{Int}(undef, N)
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
    typeof(color_scale) <: Scale.ContinuousColorScale ||
            error("HexBinGeometry requires a continuous color scale.")

    aes.color_key_title = "Count"

    Scale.apply_scale(color_scale, [aes], data)
end


struct StepStatistic <: Gadfly.StatisticElement
    direction::Symbol
end
StepStatistic(; direction=:hv) = StepStatistic(direction)

input_aesthetics(::StepStatistic) = [:x, :y]
output_aesthetics(::StepStatistic) = [:x, :y]

"""
    Stat.step[(; direction=:hv)]


Perform stepwise interpolation between the points in
$(aes2str(input_aesthetics(step()))).  If `direction` is `:hv` a horizontal
line extends to the right of each point and a vertical line below it;  if `:vh`
then vertical above and horizontal to the left.  More concretely, between
`(x[i], y[i])` and `(x[i+1], y[i+1])`, either `(x[i+1], y[i])` or `(x[i],
y[i+1])` is inserted, for `:hv` and `:vh`, respectively.
"""
const step = StepStatistic

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

    x_step = Array{eltype(aes.x)}(undef, 0)
    y_step = Array{eltype(aes.y)}(undef, 0)
    color_step = aes.color == nothing ? nothing : Array{eltype(aes.color)}(undef, 0)
    group_step = aes.group == nothing ? nothing : Array{eltype(aes.group)}(undef, 0)

    i = 1
    i_offset = 1
    while true
        u = i_offset + div(i - 1, 2) + (isodd(i) || stat.direction != :hv ? 0 : 1)
        v = i_offset + div(i - 1, 2) + (isodd(i) || stat.direction != :vh ? 0 : 1)

        (u > length(aes.x) || v > length(aes.y)) && break

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


struct FunctionStatistic <: Gadfly.StatisticElement
    # Number of points to evaluate the function at
    num_samples::Int
end
FunctionStatistic(; num_samples=250) = FunctionStatistic(num_samples)

input_aesthetics(::FunctionStatistic) = [:y, :xmin, :xmax]
output_aesthetics(::FunctionStatistic) = [:x, :y, :group]
default_scales(::FunctionStatistic) = [Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous()]

"""
    Stat.func[(; num_samples=250)]

Transform the functions or expressions in $(aes2str(input_aesthetics(func())))
into points in $(aes2str(output_aesthetics(func()))).
"""
const func = FunctionStatistic

function apply_statistic(stat::FunctionStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("FunctionStatistic", aes, :y)
    Gadfly.assert_aesthetics_defined("FunctionStatistic", aes, :xmin)
    Gadfly.assert_aesthetics_defined("FunctionStatistic", aes, :xmax)
    Gadfly.assert_aesthetics_equal_length("FunctionStatistic", aes, :xmin, :xmax)

    aes.x = Array{Float64}(undef, length(aes.y) * stat.num_samples)
    ys = Array{Float64}(undef, length(aes.y) * stat.num_samples)

    i = 1
    for (f, xmin, xmax) in zip(aes.y, cycle(aes.xmin), cycle(aes.xmax))
        for x in range(xmin, stop=xmax, length=stat.num_samples)
            aes.x[i] = x
            ys[i] = f(x)
            i += 1
        end
    end

    # color was bound explicitly
    if aes.color != nothing
        func_color = aes.color
        aes.color = Array{eltype(aes.color)}(undef, length(aes.y) * stat.num_samples)
        groups = Array{Int}(undef, length(aes.y) * stat.num_samples)
        for i in 1:length(aes.y)
            aes.color[1+(i-1)*stat.num_samples:i*stat.num_samples] .= func_color[i]
            groups[1+(i-1)*stat.num_samples:i*stat.num_samples] .= i
        end
        aes.group = discretize_make_ia(groups)
    elseif length(aes.y) > 1 && haskey(scales, :color)
        data = Gadfly.Data()
        data.color = Array{AbstractString}(undef, length(aes.y) * stat.num_samples)
        groups = Array{Union{Missing,Int}}(undef, length(aes.y) * stat.num_samples)
        for i in 1:length(aes.y)
            fname = "f<sub>$(i)</sub>"
            data.color[1+(i-1)*stat.num_samples:i*stat.num_samples] .= fname
            groups[1+(i-1)*stat.num_samples:i*stat.num_samples] .= i
        end
        Scale.apply_scale(scales[:color], [aes], data)
        aes.group = discretize_make_ia(groups)
    end

    data = Gadfly.Data()
    data.y = ys
    Scale.apply_scale(scales[:y], [aes], data)
end


struct ContourStatistic <: Gadfly.StatisticElement
    levels::Union{Int,Vector,Function}
    samples::Int
end
ContourStatistic(; levels=15, samples=150) = ContourStatistic(levels, samples)

input_aesthetics(::ContourStatistic) = [:z, :x, :y, :xmin, :xmax, :ymin, :ymax]
output_aesthetics(::ContourStatistic) = [:x, :y, :color, :group]
default_scales(::ContourStatistic, t::Gadfly.Theme=Gadfly.current_theme()) =
        [Gadfly.Scale.z_func(), Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous(),
            t.continuous_color_scale]

"""
    Stat.contour[(; levels=15, samples=150)]

Transform the 2D function, matrix, or DataFrame in the `z` aesthetic into a set of
lines in `x` and `y` showing the iso-level contours.  A function requires that
either the `x` and `y` or the `xmin`, `xmax`, `ymin` and `ymax` aesthetics also
be defined.  The latter are interpolated using `samples`.  A matrix and
DataFrame can optionally input `x` and `y` aesthetics to specify the
coordinates of the rows and columns, respectively.  In each case `levels` sets
the number of contours to draw:  either a vector of contour levels, an integer
that specifies the number of contours to draw, or a function which inputs `z`
and outputs either a vector or an integer.  Used by [`Geom.contour`](@ref
Gadfly.Geom.contour).
"""
const contour = ContourStatistic

function apply_statistic(stat::ContourStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    xs = aes.x === nothing ? nothing : convert(Vector{Float64}, aes.x)
    ys = aes.y === nothing ? nothing : convert(Vector{Float64}, aes.y)

    if typeof(aes.z) <: Function
        if xs == nothing && aes.xmin != nothing && aes.xmax != nothing
            xs = range(aes.xmin[1], stop=aes.xmax[1], length=stat.samples)
        end

        if ys == nothing && aes.ymin != nothing && aes.ymax != nothing
            ys = range(aes.ymin[1], stop=aes.ymax[1], length=stat.samples)
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
        size(zs) != (length(xs), length(ys)) &&
                error("Stat.contour requires dimension of z to be length(x) by length(y)")
    elseif typeof(aes.z) <: Vector
        z = Vector{Float64}(aes.z)
        a = [xs ys z]
        as = sortslices(a, dims=1, by=x->(x[2],x[1]))
        xs = unique(as[:,1])
        ys = unique(as[:,2])
        zs = Array{Float64}(undef, length(xs), length(ys))
        zs[:,:] = as[:,3]
    else
        error("Stat.contour requires either a matrix, function or dataframe")
    end

    levels = Float64[]
    contour_xs = eltype(xs)[]
    contour_ys = eltype(ys)[]

    stat_levels = typeof(stat.levels) <: Function ? stat.levels(zs) : stat.levels

    groups = discretize_make_ia(Int[])
    group = 0
    for level in Contour.levels(Contour.contours(xs, ys, zs, stat_levels))
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


struct QQStatistic <: Gadfly.StatisticElement end

input_aesthetics(::QQStatistic) = [:x, :y]
output_aesthetics(::QQStatistic) = [:x, :y]
default_scales(::QQStatistic) =
        [Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous]

"""
    Stat.qq

Transform $(aes2str(input_aesthetics(qq()))) into cumulative distrubutions.
If each is a numeric vector, their sample quantiles will be compared.  If one
is a `Distribution`, then its theoretical quantiles will be compared with the
sample quantiles of the other.
"""
const qq = QQStatistic

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


struct ViolinStatistic <: Gadfly.StatisticElement
    n::Int # Number of points sampled
end
ViolinStatistic() = ViolinStatistic(300)

input_aesthetics(::ViolinStatistic) = [:x, :y, :color]
output_aesthetics(::ViolinStatistic) = [:x, :y, :width, :color]
default_scales(stat::ViolinStatistic) = [Gadfly.Scale.x_discrete(), Gadfly.Scale.y_continuous()]

### very similar to Stat.density; Geom.violin could be refactored to us it instead
"""
    Stat.violin[(n=300)]

Transform $(aes2str(input_aesthetics(violin()))).
"""
const violin = ViolinStatistic

function apply_statistic(stat::ViolinStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)

    isa(aes.y[1], Real) || error("Kernel density estimation only works on Real types.")

    grouped_y = Dict(1=>aes.y)
    grouped_color = Dict{Int, Gadfly.ColorOrNothing}(1=>nothing)
    ux = unique(aes.x)
    uxflag = length(ux) < length(aes.x)
    colorflag = aes.color != nothing

    uxflag && (grouped_y = Dict(x=>aes.y[aes.x.==x] for x in ux))

    grouped_color = (colorflag ? Dict(x=>first(aes.color[aes.x.==x]) for x in ux) : 
        uxflag && Dict(x=>nothing for x in ux) )

    aes.x     = Array{Float64}(undef, 0)
    aes.y     = Array{Float64}(undef, 0)
    aes.width = Array{Float64}(undef, 0)
    colors = eltype(aes.color)[]

    for (x, ys) in grouped_y
        window = stat.n > 1 ? KernelDensity.default_bandwidth(ys) : 0.1
        f = KernelDensity.kde(ys, bandwidth=window, npoints=stat.n)
        append!(aes.x, fill(x, length(f.x)))
        append!(aes.y, f.x)
        append!(aes.width, f.density)
        append!(colors, fill(grouped_color[x], length(f.x)))
    end

    colorflag && (aes.color = colors)

    pad = 0.1
    maxwidth = maximum(aes.width)
    broadcast!(*, aes.width, aes.width, 1 - pad)
    broadcast!(/, aes.width, aes.width, maxwidth)
end


struct JitterStatistic <: Gadfly.StatisticElement
    vars::Vector{Symbol}
    range::Float64
    seed::UInt32
end
JitterStatistic(vars; range=0.8, seed=0x0af5a1f7) = JitterStatistic(vars, range, seed)

input_aesthetics(stat::JitterStatistic) = stat.vars
output_aesthetics(stat::JitterStatistic) = stat.vars

xy_jitter(var) = """
    Stat.$(var)_jitter[(; range=0.8, seed=0x0af5a1f7)]

Add a random number to the `$var` aesthetic, which is typically categorical, to
reduce the likelihood that points overlap.  The maximum jitter is `range` times
the smallest non-zero difference between two points.
"""

@doc xy_jitter("x")  x_jitter(; range=0.8, seed=0x0af5a1f7) = JitterStatistic([:x], range=range, seed=seed)

@doc xy_jitter("y")  y_jitter(; range=0.8, seed=0x0af5a1f7) = JitterStatistic([:y], range=range, seed=seed)

function minimum_span(vars::Vector{Symbol}, aes::Gadfly.Aesthetics)
    span = nothing
    for var in vars
        data = getfield(aes, var)
        length(data) < 2 && continue
        dataspan = data[2] - data[1]
        T = eltype(data)
        z = convert(T, zero(T))
        sorteddata = sort(data)
        for δ in diff(sorteddata)
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
    span == nothing && return

    rng = MersenneTwister(stat.seed)
    for var in stat.vars
        data = getfield(aes, var)
        outdata = Array{Float64}(undef, size(data))
        broadcast!(+, outdata, data, stat.range * (rand(rng, length(data)) .- 0.5) .* span)
        setfield!(aes, var, outdata)
    end
end


# Bin mean returns the mean of x and y in n bins of x
struct BinMeanStatistic <: Gadfly.StatisticElement
    n::Int
end
BinMeanStatistic(; n=20) = BinMeanStatistic(n)

input_aesthetics(::BinMeanStatistic) = [:x, :y]
output_aesthetics(::BinMeanStatistic) = [:x, :y]

"""
    Stat.binmean[(; n=20)]

Transform the $(aes2str(input_aesthetics(binmean()))) into `n` bins each
of which contains the mean within than bin.
"""
const binmean = BinMeanStatistic

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
        colors = Array{RGB{Float32}}(undef, 0)
        aes.x = Array{Tx}(undef, 0)
        aes.y = Array{Ty}(undef, 0)
        for (c, v) in groups
            (fx, fy) = mean_by_group(v[1], v[2], breaks)
            append!(aes.x, fx)
            append!(aes.y, fy)
            for _ in 1:length(fx)
                push!(colors, c)
            end
        end
        aes.color = discretize_make_ia(colors)
    end
end

function mean_by_group(x::Vector{Tx}, y::Vector{Ty}, breaks::Vector{Float64}) where {Tx, Ty}
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


struct EnumerateStatistic <: Gadfly.StatisticElement
    var::Symbol
end

input_aesthetics(stat::EnumerateStatistic) = [stat.var]
output_aesthetics(stat::EnumerateStatistic) = [stat.var]

function default_scales(stat::EnumerateStatistic)
    if stat.var == :y
        return [Gadfly.Scale.y_continuous()]
    elseif stat.var == :x
        return [Gadfly.Scale.x_continuous()]
    else
        return Gadfly.ScaleElement[]
    end
end

# only used internally
const x_enumerate = EnumerateStatistic(:x)

# only used internally
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


struct VecFieldStatistic <: Gadfly.StatisticElement
    smoothness::Float64
    scale::Float64
    samples::Int64
end
VecFieldStatistic(; smoothness=1.0, scale=1.0, samples=20) =
        VecFieldStatistic(smoothness, scale, samples)

input_aesthetics(stat::VecFieldStatistic) = [:z, :x, :y, :color, :xmin, :xmax, :ymin, :ymax]
output_aesthetics(stat::VecFieldStatistic) = [:x, :y, :xend, :yend, :color]
default_scales(stat::VecFieldStatistic, t::Gadfly.Theme=Gadfly.current_theme()) =
        [Gadfly.Scale.z_func(), Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous(),
            t.continuous_color_scale ]

"""
    Stat.vectorfield[(; smoothness=1.0, scale=1.0, samples=20)]

Transform the 2D function or matrix in the `z` aesthetic into a set of lines
from `x`, `y` to `xend`, `yend` showing the gradient vectors.  A function
requires that either the `x` and `y` or the `xmin`, `xmax`, `ymin` and `ymax`
aesthetics also be defined.  The latter are interpolated using `samples`.  A
matrix can optionally input `x` and `y` aesthetics to specify the coordinates
of the rows and columns, respectively.  In each case, `smoothness` can vary
from 0 to Inf;  and `scale` sets the size of vectors.
"""
const vectorfield = VecFieldStatistic

function apply_statistic(stat::VecFieldStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    xs = aes.x === nothing ? nothing : Float64.(aes.x)
    ys = aes.y === nothing ? nothing : Float64.(aes.y)

    if isa(aes.z, Function)
        if xs == nothing && aes.xmin != nothing && aes.xmax != nothing
            xs = range(aes.xmin[1], stop=aes.xmax[1], length=stat.samples)
        end
        if ys == nothing && aes.ymin != nothing && aes.ymax != nothing
            ys = range(aes.ymin[1], stop=aes.ymax[1], length=stat.samples)
        end

        zs = Float64[aes.z(x, y) for x in xs, y in ys]

    elseif isa(aes.z, Matrix)
        zs = Float64.(aes.z)

        if xs == nothing
            xs = collect(Float64, 1:size(zs)[1])
        end
        if ys == nothing
            ys = collect(Float64, 1:size(zs)[2])
        end
        if size(zs) != (length(xs), length(ys))
            error("Stat.vectorfield requires dimension of z to be length(x) by length(y)")
        end
    else
        error("Stat.vectorfield requires either a matrix or a function")
    end

    X = vcat([[x y] for x in xs, y in ys]...)
    Z = vec(zs)
    # The next two lines make use of the package CoupledFields.jl
    kpars = GaussianKP(X)
    ∇g = hcat(gradvecfield([stat.smoothness -7.0], X, Z[:,1:1], kpars)...)'
    vecf = [X-∇g*stat.scale X+∇g*stat.scale]

    aes.z = nothing
    aes.x = vecf[:,1]
    aes.y = vecf[:,2]
    aes.xend = vecf[:,3]
    aes.yend = vecf[:,4]
    color_scale = get(scales, :color, Gadfly.Scale.color_continuous_gradient())
    Scale.apply_scale(color_scale, [aes], Gadfly.Data(color=Z))
end


struct HairStatistic <: Gadfly.StatisticElement
    intercept
    orientation::Symbol # :horizontal or :vertical like BarStatistic
end
HairStatistic(;intercept=0.0, orientation=:vertical) = HairStatistic(intercept, orientation)

input_aesthetics(stat::HairStatistic) = [:x, :y]
output_aesthetics(stat::HairStatistic) = [:x, :y, :xend, :yend]
default_scales(stat::HairStatistic) = [Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous()]

"""
    Stat.hair[(; intercept=0.0, orientation=:vertical)]

Transform points in $(aes2str(input_aesthetics(hair()))) into lines in
$(aes2str(output_aesthetics(hair()))).  Used by [`Geom.hair`](@ref Gadfly.Geom.hair).
"""
const hair = HairStatistic

function apply_statistic(stat::HairStatistic,
                         scales::Dict{Symbol, Gadfly.ScaleElement},
                         coord::Gadfly.CoordinateElement,
                         aes::Gadfly.Aesthetics)
    if stat.orientation == :vertical
        aes.xend = aes.x
        aes.yend = fill(stat.intercept, length(aes.y))
    else
        aes.yend = aes.y
        aes.xend = fill(stat.intercept, length(aes.x))
    end
end


struct EllipseStatistic <: Gadfly.StatisticElement
    distribution::Type{<:ContinuousMultivariateDistribution}
    levels::Vector{<:AbstractFloat}
    nsegments::Int
end

function EllipseStatistic(;
        distribution::(Type{<:ContinuousMultivariateDistribution})=MvNormal,
        levels::Vector{Float64}=[0.95],
        nsegments::Int=51 )
    return EllipseStatistic(distribution, levels, nsegments)
end

input_aesthetics(stat::EllipseStatistic) = [:x, :y]
output_aesthetics(stat::EllipseStatistic) = [:x, :y]
default_scales(stat::EllipseStatistic) = [Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous()]

"""
    Stat.ellipse[(; distribution=MvNormal, levels=[0.95], nsegments=51)]

Transform the points in $(aes2str(input_aesthetics(ellipse()))) into set of a
lines in $(aes2str(output_aesthetics(ellipse()))).  `distribution` specifies a
multivariate distribution to use; `levels` the quantiles for which confidence
ellipses are calculated; and `nsegments` the number of segments with which to
draw each ellipse.  Used by [`Geom.ellipse`](@ref Gadfly.Geom.ellipse).
"""
const ellipse = EllipseStatistic

function apply_statistic(stat::EllipseStatistic,
    scales::Dict{Symbol, Gadfly.ScaleElement},
    coord::Gadfly.CoordinateElement,
    aes::Gadfly.Aesthetics)    

    Dat = [aes.x aes.y]
    colorflag = aes.color != nothing
    groupflag = aes.group != nothing
    aes_color = colorflag ? aes.color : fill(nothing, length(aes.x)) 
    aes_group = groupflag ? aes.group : fill(nothing, length(aes.x))
    CT, GT = eltype(aes_color), eltype(aes_group)

    groups = collect(Tuple{CT, GT}, zip(aes_color, aes_group))
    ug = unique(groups)

    V = Matrix{eltype(Dat)}
    K = Tuple{CT, GT}
    grouped_xy = Dict{K, V}(g=>Dat[groups.==[g],:] for g in ug)

    pcolors = CT[]
    pgroups = GT[]
    ellipse_x = eltype(Dat)[]
    ellipse_y = eltype(Dat)[]
    aes.linestyle = String[]

    dfn = 2
    θ = 2π*(0:stat.nsegments)/stat.nsegments
    n = length(θ)
    for (g, data) in grouped_xy
        dfd = size(data,1)-1
        dhat = fit(stat.distribution, permutedims(data,[2,1]))
        Σ½ = cholesky(cov(dhat)).U
        ellxy =  [cos.(θ) sin.(θ)] * Σ½
        μ = mean(dhat)
        for p in stat.levels
            r = sqrt(dfn*quantile(FDist(dfn,dfd), p))
            append!(ellipse_x, r*ellxy[:,1].+μ[1])
            append!(ellipse_y, r*ellxy[:,2].+μ[2])
            append!(pcolors, fill(g[1], n))
            append!(pgroups, fill(g[2], n))
            append!(aes.linestyle, fill("$(p)", n))
        end
    end

    colorflag && (aes.color = pcolors)
    groupflag && (aes.group = discretize_make_ia(pgroups))
    aes.x = ellipse_x
    aes.y = ellipse_y
    linestyle_scale = get(scales, :linestyle, Scale.linestyle_discrete())
    Scale.apply_scale(linestyle_scale, [aes], Gadfly.Data(linestyle = aes.linestyle))
end


struct DodgeStatistic <: Gadfly.StatisticElement
    position::Symbol
    axis::Symbol
end
DodgeStatistic(; position::Symbol=:dodge, axis::Symbol=:x) = DodgeStatistic(position, axis)

input_aesthetics(stat::DodgeStatistic) = [:x, :y]
output_aesthetics(stat::DodgeStatistic) = [:x, :y]
default_scales(stat::DodgeStatistic) = [Gadfly.Scale.x_continuous(), Gadfly.Scale.y_continuous()]

"""
    Stat.dodge[(; position=:dodge, axis=:x)]

Transform the points in $(aes2str(input_aesthetics(dodge()))) into set of dodged or stacked points
 in $(aes2str(output_aesthetics(dodge()))).  `position` is `:dodge` or `:stack`.
`axis` is `:x` or `:y`.
"""
const dodge = DodgeStatistic


function apply_statistic(stat::DodgeStatistic,
                            scales::Dict{Symbol, Gadfly.ScaleElement},
                            coord::Gadfly.CoordinateElement,
                            aes::Gadfly.Aesthetics)

    aes.color==nothing && return
    nbars = length(unique(aes.color))
    othervar = (stat.axis == :x) ? :y : :x
    vals = getfield(aes, stat.axis)
    
    if stat.position==:dodge
        nbars == length(aes.color) && return
        offset = range(-0.5+0.5/nbars, stop=0.5, step=1/nbars)
        dodge = getindex(offset, aes.color.index)
        setfield!(aes, stat.axis, vals.+dodge)
    elseif stat.position==:stack
        ovals = getfield(aes, othervar)
        if nbars == length(aes.color)
            setfield!(aes, othervar, 0.5*ovals)
        else
            idxs = isa(aes.color, IndirectArray) ? sortperm(aes.color.index, rev=true) : 1:length(aes.color)
            idxs2 = sortperm(idxs)
            m1 = reshape(idxs, :, nbars)
            m2 = cumsum(ovals[m1], dims=2) .- 0.5*ovals[m1]
            setfield!(aes, othervar, m2[idxs2])
        end
    else
        error("position can be :dodge (default) or :stack")
    end
end






end # module Stat
