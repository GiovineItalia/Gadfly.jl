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
    default_aes.color = RGBA{Float32}[theme.default_color]
    default_aes.size = Measure[theme.point_size]
    default_aes.alpha = Float64[theme.alphas[1]]
    aes = inherit(aes, default_aes)

    aes_size = if eltype(aes.size) <: Int
      size_min, size_max = extrema(aes.size)
      size_range = size_max - size_min
      point_size_range = theme.point_size_max - theme.point_size_min
      theme.point_size_min .+ ((aes.size .- size_min) ./ size_range .* point_size_range)
    else
        aes.size
    end

    aes_alpha = eltype(aes.alpha) <: Int ? theme.alphas[aes.alpha] : aes.alpha
    aes_shape = eltype(aes.shape) <: Function ? aes.shape : theme.point_shapes[aes.shape]
    strokef = aes.color_key_continuous != nothing && aes.color_key_continuous ?
                    theme.continuous_highlight_color : theme.discrete_highlight_color
    
    CT, ST, SZT, AT =  eltype(aes.color), eltype(aes_shape), eltype(aes_size), eltype(aes_alpha)
    groups =   collect(Tuple{CT, SZT, ST, AT}, Compose.cyclezip(aes.color, aes_size, aes_shape, aes_alpha))
    ug = unique(groups)
    ctx = context()

    if length(groups)==1
        color, size, shape, alpha = groups[1]
        compose!(ctx, (context(),
            shape(aes.x, aes.y, [size]), fill(color), stroke(strokef(color)), fillopacity(alpha),
            svgclass("marker")))
    elseif length(groups)>1
        for g in ug
            i = findall(x->isequal(x, g), groups)
            color, size, shape, alpha = g
            class = svg_color_class_from_label(aes.color_label([color])[1])
            compose!(ctx, (context(),
                    (context(), shape(view(aes.x,i), view(aes.y,i), [size]), svgclass("marker")),
                    fill(color), stroke(strokef(color)), fillopacity(alpha), svgclass(class)))
        end
    end

    compose!(ctx, linewidth(theme.highlight_width))

    return compose!(context(order=4), svgclass("geometry"), ctx)
end
