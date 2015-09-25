
immutable VLineGeometry <: Gadfly.GeometryElement
    color::@compat(Union{Color, (@compat Void)})
    size::@compat(Union{Measure, (@compat Void)})
    tag::Symbol

    function VLineGeometry(; color=nothing,
                           size::@compat(Union{Measure, (@compat Void)})=nothing,
                           tag::Symbol=empty_tag)
        new(color === nothing ? nothing : Colors.color(color), size, tag)
    end
end

const vline = VLineGeometry


    function element_aesthetics(::VLineGeometry)
    [:xintercept]
end


# Generate a form for the vline geometry
function render(geom::VLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.vline", aes, :xintercept)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size

    line_style = theme.line_style == nothing ? [] : [strokedash(Gadfly.getStrokeVector(theme.line_style))]

    return compose!(
        context(),
        Compose.line([[(x, 0h), (x, 1h)] for x in aes.xintercept], geom.tag),
        stroke(color),
        linewidth(size),
        svgclass("yfixed"),
        line_style...)
end
