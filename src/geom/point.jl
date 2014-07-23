
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
function render(geom::PointGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    default_aes.size = Measure[theme.default_point_size]
    aes = inherit(aes, default_aes)

    lw_hover_scale = 10
    lw_ratio = theme.line_width / aes.size[1]

    ctx = compose!(
        context(),
        circle(aes.x, aes.y, aes.size),
        fill(aes.color),
        linewidth(theme.highlight_width))

    if aes.color_key_continuous != nothing && aes.color_key_continuous
        compose!(ctx,
            stroke(map(theme.continuous_highlight_color, aes.color)))
    else
        compose!(ctx,
            stroke(map(theme.discrete_highlight_color, aes.color)),
            svgclass([svg_color_class_from_label(escape_id(aes.color_label([c])[1]))
                      for c in aes.color]))
    end

    return compose!(context(order=4), svgclass("geometry"), ctx)
end


