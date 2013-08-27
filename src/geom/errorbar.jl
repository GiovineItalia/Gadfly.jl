
immutable ErrorBarGeometry <: Gadfly.GeometryElement
end

immutable XErrorBarGeometry <: Gadfly.GeometryElement
end

immutable YErrorBarGeometry <: Gadfly.GeometryElement
end

const errorbar = ErrorBarGeometry
const xerrorbar = XErrorBarGeometry
const yerrorbar = YErrorBarGeometry


function element_aesthetics(::ErrorBarGeometry)
    [:x, :y, :xmin, :xmax, :ymin, :ymax]
end

function element_aesthetics(::YErrorBarGeometry)
    [:x, :ymin, :ymax]
end

function element_aesthetics(::XErrorBarGeometry)
    [:y, :xmin, :xmax]
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
    # check for X and Y error bar aesthetics
    if isempty(Gadfly.undefined_aesthetics(aes, element_aesthetics(xerrorbar())...))
        xform = render(xerrorbar(), theme, aes)
    else
        xform = empty_form
    end
    if isempty(Gadfly.undefined_aesthetics(aes, element_aesthetics(yerrorbar())...))
        yform = render(yerrorbar(), theme, aes)
    else
        yform = empty_form
    end
    xform | yform
end

function render(geom::YErrorBarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
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

function render(geom::XErrorBarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
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
            # left cap
            lines([[(xmin, y*cy - caplen), (xmin, y*cy + caplen)]
                   for (xmin, y) in zip(aes.xmin, aes.y)]...),

            # error bar
            lines([[(xmin, y*cy), (xmax, y*cy)]
                   for (xmin, xmax, y) in zip(aes.xmin, aes.xmax, aes.y)]...),

            # right cap
            lines([[(xmax, y*cy - caplen), (xmax, y*cy + caplen)]
                   for (xmax, y) in zip(aes.xmax, aes.y)]...)),

        stroke([theme.highlight_color(c) for c in aes.color]),
        linewidth(theme.line_width),
        aes.color_key_continuous == true ?
            svgclass("geometry") :
            svgclass([@sprintf("geometry color_%s", escape_id(aes.color_label(c)))
                      for c in aes.color]))
end
