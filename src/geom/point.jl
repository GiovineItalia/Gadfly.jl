# Geometry which displays points at given (x, y) positions.

immutable PointGeometry <: Gadfly.GeometryElement
    tag::Symbol
end
PointGeometry(; tag=empty_tag) = PointGeometry(tag)

const point = PointGeometry

element_aesthetics(::PointGeometry) = [:x, :y, :size, :color, :shape]

# Generate a form for a point geometry.
#
# Args:
#   geom: point geometry.
#   theme: the plot's theme.
#   aes: aesthetics.
#
# Returns:
#   A compose Form.
#
function render(geom::PointGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes, :x, :y)

    default_aes = Gadfly.Aesthetics()
    default_aes.shape = Function[Shape.circle]
    default_aes.color = PooledDataArray(RGBA{Float32}[theme.default_color])
    default_aes.size = Measure[theme.point_size]
    aes = inherit(aes, default_aes)

    if eltype(aes.size) <: Int
      size_min, size_max = extrema(aes.size)
      size_range = size_max - size_min
      point_size_range = theme.point_size_max - theme.point_size_min
      interpolate_size(x) = theme.point_size_min + (x-size_min) / size_range * point_size_range
    end

    ctx = context()

    for (x, y, color, size, shape) in Compose.cyclezip(aes.x, aes.y, aes.color, aes.size, aes.shape)
        shapefun = typeof(shape) <: Function ? shape : theme.point_shapes[shape]
        sizeval = typeof(size) <: Int ? interpolate_size(size) : size
        strokecolor = aes.color_key_continuous != nothing && aes.color_key_continuous ?
                    theme.continuous_highlight_color(color) :
                    theme.discrete_highlight_color(color)
        class = svg_color_class_from_label(aes.color_label([color])[1])
        compose!(ctx, (context(), shapefun([x], [y], [sizeval]), fill(color), stroke(strokecolor),
              svgclass(class)))
    end

    compose!(ctx, linewidth(theme.highlight_width))

    return compose!(context(order=4), svgclass("geometry"), ctx)
end
