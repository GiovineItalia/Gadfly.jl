
immutable VLineGeometry <: Gadfly.GeometryElement
	color::Union(ColorValue, Nothing)
	size::Union(Measure, Nothing)

	function VLineGeometry(; color::Union(ColorValue, Nothing)=nothing,
		                   size::Union(Measure, Nothing)=nothing)
		new(color, size)
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
	size = geom.size === nothing ? theme.line_width : geom.line
	compose(
		combine([lines((x, 0h), (x, 1h)) for x in aes.xintercept]...),
		stroke(color), linewidth(size),
		svgclass("guide"))
end
