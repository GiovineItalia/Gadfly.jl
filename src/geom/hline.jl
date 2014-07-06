
immutable HLineGeometry <: Gadfly.GeometryElement
    color::Union(ColorValue, Nothing)
    size::Union(Measure, Nothing)

    function HLineGeometry(; color=nothing,
                           size::Union(Measure, Nothing)=nothing)
        new(color === nothing ? nothing : Color.color(color),
            size)
    end
end

const hline = HLineGeometry


function element_aesthetics(::HLineGeometry)
    [:yintercept]
end


# Generate a form for the hline geometry
function render(geom::HLineGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    Gadfly.assert_aesthetics_defined("Geom.hline", aes, :yintercept)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size

    return compose!(
        context(),
        Compose.line([{(0w, y), (1w, y)} for y in aes.yintercept]),
        stroke(color),
        linewidth(size),
        svgclass("xfixed"))
end

