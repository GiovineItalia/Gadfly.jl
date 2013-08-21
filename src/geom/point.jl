
# Geometry which displays points at given (x, y) positions.
immutable PointGeometry <: Gadfly.GeometryElement
end


const point = PointGeometry


function element_aesthetics(::PointGeometry)
    [:x, :y, :size, :color]
end


# Generate a form for a point geometry.
#
# Args:
#   geom: point geometry.
#   theme: the plot's theme.
#   aes: aesthetics.
#
# Returns:
#   A compose Form.
#
function render(geom::PointGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    default_aes.size = Measure[theme.default_point_size]
    aes = inherit(aes, default_aes)

    lw0 = convert(Compose.SimpleMeasure{Compose.MillimeterUnit}, theme.line_width)
    lw1 = 10 * lw0
    compose(circle(aes.x, aes.y, aes.size),
            fill(aes.color),
            stroke([theme.highlight_color(c) for c in aes.color]),
            linewidth(theme.line_width),
            d3embed(@sprintf(".on(\"mouseover\", geom_point_mouseover(%0.2f), false)",
                             lw1.value)),
            d3embed(@sprintf(".on(\"mouseout\", geom_point_mouseover(%0.2f), false)",
                             lw0.value)),
            aes.color_key_continuous == true ?
                svgclass("geometry") :
                svgclass([@sprintf("geometry color_%s", escape_id(aes.color_label(c)))
                          for c in aes.color]))
end


