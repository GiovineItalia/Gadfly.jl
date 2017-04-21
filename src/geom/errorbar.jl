immutable ErrorBarGeometry <: Gadfly.GeometryElement
    tag::Symbol
end
ErrorBarGeometry(; tag=empty_tag) = ErrorBarGeometry(tag)


immutable XErrorBarGeometry <: Gadfly.GeometryElement
    tag::Symbol
end
XErrorBarGeometry(; tag=empty_tag) = XErrorBarGeometry(tag)

immutable YErrorBarGeometry <: Gadfly.GeometryElement
    tag::Symbol
end
YErrorBarGeometry(; tag=empty_tag) = YErrorBarGeometry(tag)

const errorbar = ErrorBarGeometry
const xerrorbar = XErrorBarGeometry
const yerrorbar = YErrorBarGeometry

element_aesthetics(::ErrorBarGeometry) = [:x, :y, :xmin, :xmax, :ymin, :ymax]
element_aesthetics(::YErrorBarGeometry) = [:x, :ymin, :ymax]
element_aesthetics(::XErrorBarGeometry) = [:y, :xmin, :xmax]

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
        xctx = render(xerrorbar(), theme, aes)
    else
        xctx = nothing
    end
    if isempty(Gadfly.undefined_aesthetics(aes, element_aesthetics(yerrorbar())...))
        yctx = render(yerrorbar(), theme, aes)
    else
        yctx = nothing
    end
    compose(context(order=3), xctx, yctx)
end

function render(geom::YErrorBarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.errorbar", aes,
                                     element_aesthetics(geom)...)
    Gadfly.assert_aesthetics_equal_length("Geom.errorbar", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGB{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)
    caplen = theme.errorbar_cap_length/2
    ttc, teb, tbc = subtags(geom.tag, :top_cap, :error_bar, :bottom_cap)

    return compose!(
        context(order=3; tag=geom.tag),

        # top cap
        Compose.line([[(x*cx - caplen, ymax), (x*cx + caplen, ymax)]
                      for (x, ymax) in zip(aes.x, aes.ymax)], ttc),

        # error bar
        Compose.line([[(x*cx, ymax), (x*cx, ymin)]
                      for (x, ymin, ymax) in zip(aes.x, aes.ymin, aes.ymax)], teb),

        # bottom cap
        Compose.line([[(x*cx - caplen, ymin), (x*cx + caplen, ymin)]
                      for (x, ymin) in zip(aes.x, aes.ymin)], tbc),

        stroke([theme.stroke_color(c) for c in aes.color]),
        linewidth(theme.line_width),
        aes.color_key_continuous == true ?
            svgclass("geometry") :
            svgclass([string("geometry ", svg_color_class_from_label(aes.color_label([c])[1]))
                      for c in aes.color]))
end

function render(geom::XErrorBarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.errorbar", aes,
                                     element_aesthetics(geom)...)
    Gadfly.assert_aesthetics_equal_length("Geom.errorbar", aes,
                                          element_aesthetics(geom)...)

    colored = aes.color != nothing
    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGB{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)
    caplen = theme.errorbar_cap_length/2
    tlc, teb, trc = subtags(geom.tag, :left_cap, :error_bar, :right_cap)

    return compose!(
        context(order=3, tag=geom.tag),

        # left cap
        Compose.line([[(xmin, y*cy - caplen), (xmin, y*cy + caplen)]
                      for (xmin, y) in zip(aes.xmin, aes.y)], tlc),

        # error bar
        Compose.line([[(xmin, y*cy), (xmax, y*cy)]
                      for (xmin, xmax, y) in zip(aes.xmin, aes.xmax, aes.y)], teb),

        # right cap
        Compose.line([[(xmax, y*cy - caplen), (xmax, y*cy + caplen)]
                      for (xmax, y) in zip(aes.xmax, aes.y)], trc),

        stroke([theme.stroke_color(c) for c in aes.color]),
        linewidth(theme.line_width),
        (aes.color_key_continuous == true || !colored) ?
            svgclass("geometry") :
            svgclass([string("geometry ", svg_color_class_from_label(aes.color_label([c])[1]))
                      for c in aes.color]))
end
