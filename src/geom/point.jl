# Geometry which displays points at given (x, y) positions.

struct PointGeometry <: Gadfly.GeometryElement
    tag::Symbol
end
PointGeometry(; tag=empty_tag) = PointGeometry(tag)

"""
    Geom.point

Draw scatter plots of the `x` and `y` aesthetics.

# Optional Aesthetics
- `color`: Categorical data will choose maximally distinguishable colors from
  the LCHab color space.  Continuous data will map onto LCHab as well.  Colors
  can also be specified explicitly for each data point with a vector of colors of
  length(x).  A vector of length one specifies the color to use for all points.
  Default is `Theme.default_color`.
- `shape`: Categorical data will cycle through `Theme.point_shapes`.  Shapes
  can also be specified explicitly for each data point with a vector of shapes of
  length(x).  A vector of length one specifies the shape to use for all points.
  Default is `Theme.point_shapes[1]`.
- `size`: Categorical data and vectors of `Ints` will interpolate between
  `Theme.point_size_{min,max}`.  A continuous vector of `AbstractFloats` or
  `Measures` of length(x) specifies the size of each data point explicitly.  A
  vector of length one specifies the size to use for all points.  Default is
  `Theme.point_size`.
- `alpha`: Categorical data will use the alpha palette in `Theme.alphas`.
  Continuous data will remap from 0-1. Default is `Theme.alphas[1]`.
"""
const point = PointGeometry

element_aesthetics(::PointGeometry) = [:x, :y, :size, :color, :shape, :alpha]

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
    default_aes.shape = Function[theme.point_shapes[1]]
    default_aes.color = discretize_make_ia(RGBA{Float32}[theme.default_color])
    default_aes.size = Measure[theme.point_size]
    default_aes.alpha = [theme.alphas[1]]
    aes = inherit(aes, default_aes)

    if eltype(aes.size) <: Int
      size_min, size_max = extrema(aes.size)
      size_range = size_max - size_min
      point_size_range = theme.point_size_max - theme.point_size_min
      interpolate_size(x) = theme.point_size_min + (x-size_min) / size_range * point_size_range
    end

    aes_alpha = eltype(aes.alpha) <: Int ? theme.alphas[aes.alpha] : aes.alpha

    ctx = context()

    for (x, y, color, size, shape, alpha) in Compose.cyclezip(aes.x, aes.y, aes.color, aes.size, aes.shape, aes_alpha)
        shapefun = typeof(shape) <: Function ? shape : theme.point_shapes[shape]
        sizeval = typeof(size) <: Int ? interpolate_size(size) : size
        strokecolor = aes.color_key_continuous != nothing && aes.color_key_continuous ?
                    theme.continuous_highlight_color(color) :
                    theme.discrete_highlight_color(color)
        class = svg_color_class_from_label(aes.color_label([color])[1])
        compose!(ctx, (context(),
              (context(), shapefun([x], [y], [sizeval]), svgclass("marker")),
              fill(color), stroke(strokecolor), fillopacity(alpha), 
              svgclass(class)))
    end

    compose!(ctx, linewidth(theme.highlight_width))

    return compose!(context(order=4), svgclass("geometry"), ctx)
end
