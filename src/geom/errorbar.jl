struct ErrorBarGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    tag::Symbol
end
ErrorBarGeometry(default_statistic=Gadfly.Stat.identity(); tag=empty_tag) = 
    ErrorBarGeometry(default_statistic, tag)


struct XErrorBarGeometry <: Gadfly.GeometryElement
    tag::Symbol
end
XErrorBarGeometry(; tag=empty_tag) = XErrorBarGeometry(tag)

struct YErrorBarGeometry <: Gadfly.GeometryElement
    tag::Symbol
end
YErrorBarGeometry(; tag=empty_tag) = YErrorBarGeometry(tag)

"""
    Geom.errorbar

Draw vertical error bars if the `x`, `ymin`, and `ymax` aesthetics
are specified and/or horizontal error bars for `y`, `xmin`, and `xmax`.
Optionally color them with `color`.

See also [`Geom.xerrorbar`](@ref) and [`Geom.yerrorbar`](@ref).

"""
const errorbar = ErrorBarGeometry

"""
    Geom.xerrorbar

Draw horizontal error bars at `y` from `xmin` to `xmax`.  Optionally
color them with `color`.
"""
const xerrorbar = XErrorBarGeometry

"""
    Geom.yerrorbar

Draw vertical error bars at `x` from `ymin` to `ymax`.  Optionally
color them with `color`.
"""
const yerrorbar = YErrorBarGeometry




element_aesthetics(::ErrorBarGeometry) = [:x, :y, :xmin, :xmax, :ymin, :ymax, :color]
element_aesthetics(::XErrorBarGeometry) = [:y, :xmin, :xmax, :color]
element_aesthetics(::YErrorBarGeometry) = [:x, :ymin, :ymax, :color]
default_statistic(geom::ErrorBarGeometry) = geom.default_statistic


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
    if isempty(Gadfly.undefined_aesthetics(aes, :y, :xmin, :xmax))
        xctx = render(xerrorbar(), theme, aes)
    else
        xctx = nothing
    end
    if isempty(Gadfly.undefined_aesthetics(aes, :x, :ymin, :ymax))
        yctx = render(yerrorbar(), theme, aes)
    else
        yctx = nothing
    end
    compose(context(order=3), xctx, yctx, svgclass("geometry"))
end

function render(geom::YErrorBarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.errorbar", aes, :x, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("Geom.errorbar", aes, :x, :ymin, :ymax)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGB{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)
    caplen = theme.errorbar_cap_length/2
    ttc, teb, tbc = subtags(geom.tag, :top_cap, :error_bar, :bottom_cap)

    ctx = compose!(
        context(order=3; tag=geom.tag),

        # top cap
        (context(),
            Compose.line([[(x*cx - caplen, ymax), (x*cx + caplen, ymax)]
                      for (x, ymax) in zip(aes.x, aes.ymax)], ttc),
            svgclass("marker")),

        # error bar
        Compose.line([[(x*cx, ymax), (x*cx, ymin)]
                      for (x, ymin, ymax) in zip(aes.x, aes.ymin, aes.ymax)], teb),

        # bottom cap
        (context(),
            Compose.line([[(x*cx - caplen, ymin), (x*cx + caplen, ymin)]
                      for (x, ymin) in zip(aes.x, aes.ymin)], tbc),
            svgclass("marker")),

        stroke([theme.stroke_color(c) for c in aes.color]),
        linewidth(theme.line_width))

    (aes.color_key_continuous == true || aes.color == nothing) || compose!(ctx,
            svgclass([svg_color_class_from_label(aes.color_label([c])[1]) for c in aes.color]))

    return ctx
end

function render(geom::XErrorBarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.errorbar", aes, :y, :xmin, :xmax)
    Gadfly.assert_aesthetics_equal_length("Geom.errorbar", aes, :y, :xmin, :xmax)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGB{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)
    caplen = theme.errorbar_cap_length/2
    tlc, teb, trc = subtags(geom.tag, :left_cap, :error_bar, :right_cap)

    ctx = compose!(
        context(order=3, tag=geom.tag),

        # left cap
        (context(),
            Compose.line([[(xmin, y*cy - caplen), (xmin, y*cy + caplen)]
                      for (xmin, y) in zip(aes.xmin, aes.y)], tlc),
            svgclass("marker")),

        # error bar
        Compose.line([[(xmin, y*cy), (xmax, y*cy)]
                      for (xmin, xmax, y) in zip(aes.xmin, aes.xmax, aes.y)], teb),

        # right cap
        (context(),
            Compose.line([[(xmax, y*cy - caplen), (xmax, y*cy + caplen)]
                      for (xmax, y) in zip(aes.xmax, aes.y)], trc),
            svgclass("marker")),

        stroke([theme.stroke_color(c) for c in aes.color]),
        linewidth(theme.line_width))

    (aes.color_key_continuous == true || aes.color == nothing) || compose!(ctx,
            svgclass([svg_color_class_from_label(aes.color_label([c])[1])
                      for c in aes.color]))

    return ctx
end
