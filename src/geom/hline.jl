
immutable HLineGeometry <: Gadfly.GeometryElement
    color::Union(Color, Nothing)
    size::Union(Measure, Nothing)
    tag::Symbol

    function HLineGeometry(; color=nothing,
                           size::Union(Measure, Nothing)=nothing,
                           tag::Symbol=empty_tag)
        new(color === nothing ? nothing : Colors.color(color),
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

    line_style = theme.line_style == nothing ? [] : [strokedash(Gadfly.getStrokeVector(theme.line_style))]

    return compose!(
        context(),
        Compose.line([[(0w, y), (1w, y)] for y in aes.yintercept], geom.tag),
        stroke(color),
        linewidth(size),
        svgclass("xfixed"),
        line_style...)
end
