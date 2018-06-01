struct DensityGeometry <: Gadfly.GeometryElement
    stat::Gadfly.StatisticElement
    order::Int
    tag::Symbol
end

function DensityGeometry(; order=1, tag=empty_tag, kwargs...)
    DensityGeometry(Gadfly.Stat.DensityStatistic(; kwargs...), order, tag)
end

DensityGeometry(stat; order=1, tag=empty_tag) = DensityGeometry(stat, order, tag)

const density = DensityGeometry

element_aesthetics(::DensityGeometry) = Symbol[]
default_statistic(geom::DensityGeometry) = Gadfly.Stat.DensityStatistic(geom.stat)

function render(geom::DensityGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.density", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.density", aes, :x, :y)

    grouped_data = Gadfly.groupby(aes, [:color], :y)
    densities = Array{NTuple{2, Float64}}[]
    colors = []

    for (keys, belongs) in grouped_data
        xs = aes.x[belongs]
        ys = aes.y[belongs]

        push!(densities, [(x, y) for (x, y) in zip(xs, ys)])
        push!(colors, keys[1])
    end

    ctx = context(order=geom.order)
    if geom.stat.position == :dodge
        compose!(ctx, Compose.polygon(densities, geom.tag), stroke(colors), fill(nothing))
    else
        compose!(ctx, Compose.polygon(densities, geom.tag), fill(colors))
    end

    compose!(ctx, svgclass("geometry"))
end

struct ViolinGeometry <: Gadfly.GeometryElement
    stat::Gadfly.StatisticElement
    split::Bool
    order::Int
    tag::Symbol
end
function ViolinGeometry(; order=1, tag=empty_tag, split=false, kwargs...)
    if findfirst(x->x[1] == :trim, kwargs) == 0
        push!(kwargs, (:trim, true))
    end
    ViolinGeometry(Gadfly.Stat.DensityStatistic(; kwargs...), split, order, tag)
end

"""
    Geom.violin[(; order=1)]

Draw `y` versus `width`, optionally grouping categorically by `x` and coloring
with `color`.  Alternatively, if `width` is not supplied, the data in `y` will
be transformed to a density estimate using [`Stat.violin`](@ref)
"""
const violin = ViolinGeometry

element_aesthetics(::ViolinGeometry) = [:x, :y, :color]

default_statistic(geom::ViolinGeometry) = Gadfly.Stat.DensityStatistic(geom.stat)

function render(geom::ViolinGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Geom.violin", aes, :y, :width)
    Gadfly.assert_aesthetics_equal_length("Geom.violin", aes, :y, :width)

    grouped_data = Gadfly.groupby(aes, [:x, :color], :y)
    violins = Array{NTuple{2, Float64}}[]

    colors = []
    (aes.color == nothing) && (aes.color = fill(theme.default_color, length(aes.x)))
    color_opts = unique(aes.color)
    if geom.split && length(color_opts) > 2
        error("Split violins require 2 colors, not more")
    end

    for (keys, belongs) in grouped_data
        x, color = keys
        ys = aes.y[belongs]
        ws = aes.width[belongs]

        if geom.split
            pos = findfirst(color_opts, color)
            if pos == 1
                push!(violins, [(x - w/2, y) for (y, w) in zip(ys, ws)])
            else
                push!(violins, reverse!([(x + w/2, y) for (y, w) in zip(ys, ws)]))
            end
            push!(colors, color)
        else
            push!(violins, vcat([(x - w/2, y) for (y, w) in zip(ys, ws)],
                                reverse!([(x + w/2, y) for (y, w) in zip(ys, ws)])))
            push!(colors, color != nothing ? color : theme.default_color)
        end
    end

    ctx = context(order=geom.order)
    compose!(ctx, Compose.polygon(violins, geom.tag), fill(colors))

    compose!(ctx, svgclass("geometry"))

end
