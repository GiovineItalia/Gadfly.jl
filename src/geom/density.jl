struct DensityGeometry <: Gadfly.GeometryElement
    stat::Gadfly.StatisticElement
    order::Int
    tag::Symbol
end

function DensityGeometry(; n=256,
                           bandwidth=-Inf,
                           adjust=1.0,
                           kernel=Normal,
                           trim=false,
                           scale=:area,
                           position=:dodge,
                           orientation=:horizontal,
                           order=1,
                           tag=empty_tag)
    stat = Gadfly.Stat.DensityStatistic(n, bandwidth, adjust, kernel, trim,
                                        scale, position, orientation, false)
    DensityGeometry(stat, order, tag)
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
        push!(colors, keys[1] != nothing ? keys[1] : theme.default_color)
    end

    ctx = context(order=geom.order)
    # TODO: This should be user controllable
    if geom.stat.position == :dodge
        compose!(ctx, Compose.polygon(densities, geom.tag), stroke(colors), fill(nothing))
    else
        compose!(ctx, Compose.polygon(densities, geom.tag), fill(colors))
    end

    compose!(ctx, svgclass("geometry"))
end

struct ViolinGeometry <: Gadfly.GeometryElement
    stat::Gadfly.StatisticElement
    order::Int
    tag::Symbol
end

function ViolinGeometry(; n=256,
                          bandwidth=-Inf,
                          adjust=1.0,
                          kernel=Normal,
                          trim=true,
                          scale=:area,
                          orientation=:vertical,
                          order=1,
                          tag=empty_tag)
    stat = Gadfly.Stat.DensityStatistic(n, bandwidth, adjust, kernel, trim,
                                        scale, :dodge, orientation, true)
    ViolinGeometry(stat, order, tag)
end

"""
    Geom.violin[(; order=1)]

Draw `y` versus `width`, optionally grouping categorically by `x` and coloring
with `color`.  Alternatively, if `width` is not supplied, the data in `y` will
be transformed to a density estimate using [`Stat.density`](@ref)
"""
const violin = ViolinGeometry

element_aesthetics(::ViolinGeometry) = []

default_statistic(geom::ViolinGeometry) = Gadfly.Stat.DensityStatistic(geom.stat)

function render(geom::ViolinGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Geom.violin", aes, :y, :width)
    Gadfly.assert_aesthetics_equal_length("Geom.violin", aes, :y, :width)

    output_dims, groupon = Gadfly.Stat._find_output_dims(geom.stat)
    grouped_data = Gadfly.groupby(aes, groupon, output_dims[2])
    violins = Array{NTuple{2, Float64}}[]

    (aes.color == nothing) && (aes.color = fill(theme.default_color, length(aes.x)))
    colors = eltype(aes.color)[]
    color_opts = unique(aes.color)
    split = false
    # TODO: Add support for dodging violins (i.e. having more than two colors
    # per major category). Also splitting should not happen automatically, but
    # as a optional keyword to Geom.violin
    if length(keys(grouped_data)) > 2*length(unique(getfield(aes, output_dims[1])))
        error("Violin plots do not currently support having more than 2 colors per $(output_dims[1]) category")
    elseif length(color_opts) == 2
        split = true
    end

    for (keys, belongs) in grouped_data
        x, color = keys
        ys = getfield(aes, output_dims[2])[belongs]
        ws = aes.width[belongs]

        if split
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

    if geom.stat.orientation == :horizontal
        for violin in violins
            for i in 1:length(violin)
                violin[i] = reverse(violin[i])
            end
        end
    end

    ctx = context(order=geom.order)
    compose!(ctx, Compose.polygon(violins, geom.tag), fill(colors))

    compose!(ctx, svgclass("geometry"))

end
