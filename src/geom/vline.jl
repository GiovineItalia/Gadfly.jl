
immutable VLineGeometry <: Gadfly.GeometryElement
    color::Union(ColorValue, Nothing)
    size::Union(Measure, Nothing)

    function VLineGeometry(; color=nothing,
                           size::Union(Measure, Nothing)=nothing)
        new(color === nothing ? nothing : Color.color(color), size)
    end
end

const vline = VLineGeometry


    function element_aesthetics(::VLineGeometry)
    [:xintercept]
end


# Generate a form for the vline geometry
function render(geom::VLineGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    Gadfly.assert_aesthetics_defined("Geom.vline", aes, :xintercept)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size

    return compose!(
        context(),
        Compose.line([{(x, 0h), (x, 1h)} for x in aes.xintercept]),
        stroke(color),
        linewidth(size),
        svgclass("yfixed"))
end
