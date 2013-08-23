
immutable ErrorBarGeometry <: Gadfly.GeometryElement
end


const errorbar = ErrorBarGeometry


function element_aesthetics(::ErrorBarGeometry)
    [:x, :ymin, :ymax]
end


# Generate a form for the errorbar geometry.
#
# Args:
#   geom: errorbar geometry
#   theme: the plot's theme
#   aes: aesthetics
#
# Returns:
#   A compose Form.
#
function render(geom::ErrorBarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.errorbar", aes,
                                     element_aesthetics(geom)...)
    Gadfly.assert_aesthetics_equal_length("Geom.errorbar", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    aes = inherit(aes, default_aes)

    # What are the actual extents. We can'n use 1/6
    caplen = theme.errorbar_cap_length/2

    compose(
        combine(
            # top cap
            lines([[(x*cx - caplen, ymax), (x*cx + caplen, ymax)]
                   for (x, ymax) in zip(aes.x, aes.ymax)]...),

            # error bar
            lines([[(x*cx, ymax), (x*cx, ymin)]
                   for (x, ymin, ymax) in zip(aes.x, aes.ymin, aes.ymax)]...),

            # bottom cap
            lines([[(x*cx - caplen, ymin), (x*cx + caplen, ymin)]
                   for (x, ymin) in zip(aes.x, aes.ymin)]...)),

        stroke([theme.highlight_color(c) for c in aes.color]),
        linewidth(theme.line_width),
        aes.color_key_continuous == true ?
            svgclass("geometry") :
            svgclass([@sprintf("geometry color_%s", escape_id(aes.color_label(c)))
                      for c in aes.color]))
end


