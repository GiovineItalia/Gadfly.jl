struct ViolinGeometry <: Gadfly.GeometryElement
    order::Int
    tag::Symbol
end
ViolinGeometry(; order=1, tag=empty_tag) = ViolinGeometry(order, tag)

"""
    Geom.violin[(; order=1)]

Draw `y` versus `width`, optionally grouping categorically by `x` and coloring
with `color`.  Alternatively, if `width` is not supplied, the data in `y` will
be transformed to a density estimate using [`Stat.violin`](@ref)
"""
const violin = ViolinGeometry

element_aesthetics(::ViolinGeometry) = [:x, :y, :color]

default_statistic(::ViolinGeometry) = Gadfly.Stat.violin()

function render(geom::ViolinGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    # TODO: What should we do with the color aesthetic?

    Gadfly.assert_aesthetics_defined("Geom.violin", aes, :y, :width)
    Gadfly.assert_aesthetics_equal_length("Geom.violin", aes, :y, :width)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = fill(theme.default_color, length(aes.y))
    aes = Gadfly.inherit(aes, default_aes)
    
    # Group y, width and color by x
    ux = unique(aes.x)
    grouped_color = Dict(x => first(aes.color[aes.x.==x]) for x in ux)
    grouped_y = Dict(x => aes.y[aes.x.==x] for x in ux)
    grouped_width = Dict(x => aes.width[aes.x.==x] for x in ux)

    kgy = keys(grouped_y)
    violins = [vcat([(x - w/2, y) for (y, w) in zip(grouped_y[x], grouped_width[x])],
                reverse!([(x + w/2, y) for (y, w) in zip(grouped_y[x], grouped_width[x])]))
                for x in kgy]
    colors = [grouped_color[x] for x in kgy]

    ctx = context(order=geom.order)
    compose!(ctx, Compose.polygon(violins, geom.tag), fill(colors))

    compose!(ctx, svgclass("geometry"))

end
