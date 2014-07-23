
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
function render(geom::ErrorBarGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    # check for X and Y error bar aesthetics
    if isempty(Gadfly.undefined_aesthetics(aes, element_aesthetics(xerrorbar())...))
        xctx = render(xerrorbar(), theme, aes, scales)
    else
        xctx = nothing
    end
    if isempty(Gadfly.undefined_aesthetics(aes, element_aesthetics(yerrorbar())...))
        yctx = render(yerrorbar(), theme, aes, scales)
    else
        yctx = nothing
    end
    compose(context(order=3), xctx, yctx)
end

function render(geom::YErrorBarGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    Gadfly.assert_aesthetics_defined("Geom.errorbar", aes,
                                     element_aesthetics(geom)...)
    Gadfly.assert_aesthetics_equal_length("Geom.errorbar", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    aes = inherit(aes, default_aes)
    caplen = theme.errorbar_cap_length/2

    return compose!(
        context(order=3),

        # top cap
        Compose.line([[(x*cx - caplen, ymax), (x*cx + caplen, ymax)]
                      for (x, ymax) in zip(aes.x, aes.ymax)]),

        # error bar
        Compose.line([[(x*cx, ymax), (x*cx, ymin)]
                      for (x, ymin, ymax) in zip(aes.x, aes.ymin, aes.ymax)]),

        # bottom cap
        Compose.line([[(x*cx - caplen, ymin), (x*cx + caplen, ymin)]
                      for (x, ymin) in zip(aes.x, aes.ymin)]),

        stroke([theme.stroke_color(c) for c in aes.color]),
        linewidth(theme.line_width),
        aes.color_key_continuous == true ?
            svgclass("geometry") :
            svgclass([string("geometry ", svg_color_class_from_label(aes.color_label([c])[1]))
                      for c in aes.color]))
end

function render(geom::XErrorBarGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    Gadfly.assert_aesthetics_defined("Geom.errorbar", aes,
                                     element_aesthetics(geom)...)
    Gadfly.assert_aesthetics_equal_length("Geom.errorbar", aes,
                                          element_aesthetics(geom)...)

    colored = aes.color != nothing
    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    aes = inherit(aes, default_aes)
    caplen = theme.errorbar_cap_length/2

    return compose!(
        context(order=3),

        # top cap
        Compose.line([[(xmin, y*cy - caplen), (xmin, y*cy + caplen)]
                      for (xmin, y) in zip(aes.xmin, aes.y)]),

        # error bar
        Compose.line([[(xmin, y*cy), (xmax, y*cy)]
                      for (xmin, xmax, y) in zip(aes.xmin, aes.xmax, aes.y)]),

        # right cap
        Compose.line([[(xmax, y*cy - caplen), (xmax, y*cy + caplen)]
                      for (xmax, y) in zip(aes.xmax, aes.y)]),

        stroke([theme.stroke_color(c) for c in aes.color]),
        linewidth(theme.line_width),
        (aes.color_key_continuous == true || !colored) ?
            svgclass("geometry") :
            svgclass([string("geometry ", svg_color_class_from_label(aes.color_label([c])[1]))
                      for c in aes.color]))
end
