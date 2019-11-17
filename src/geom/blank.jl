

struct BlankGeometry <: Gadfly.GeometryElement
end

"""
    Geom.blank

A blank geometry is drawn, and guides maybe drawn if aesthetics are provided.
"""
blank = BlankGeometry

element_aesthetics(::BlankGeometry) = [:x, :y, :size, :color, :shape]


function render(geom::BlankGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    ctx = context()
    return compose!(ctx, svgclass("geometry"))
end
