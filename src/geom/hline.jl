
immutable HLineGeometry <: Gadfly.GeometryElement
    color::@compat(Union{Color, (@compat Void)})
    size::@compat(Union{Measure, (@compat Void)})
    tag::Symbol

    function HLineGeometry(; color=nothing,
                           size::@compat(Union{Measure, (@compat Void)})=nothing,
                           tag::Symbol=empty_tag)
        new(color === nothing ? nothing : parse_colorant(color),
            size, tag)
    end
end

const hline = HLineGeometry


function element_aesthetics(::HLineGeometry)
    [:yintercept]
end


# Generate a form for the hline geometry
function render(geom::HLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.hline", aes, :yintercept)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size
    line_style = Gadfly.get_stroke_vector(theme.line_style)

    return compose!(
        context(),
        Compose.line([[(0w, y), (1w, y)] for y in aes.yintercept], geom.tag),
        stroke(color),
        linewidth(size),
        strokedash(line_style),
        svgclass("xfixed"))
end
