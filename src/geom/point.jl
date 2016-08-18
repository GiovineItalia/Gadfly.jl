
# Geometry which displays points at given (x, y) positions.
immutable PointGeometry <: Gadfly.GeometryElement
    tag::Symbol

    function PointGeometry(; tag::Symbol=empty_tag)
        new(tag)
    end
end


const point = PointGeometry


function element_aesthetics(::PointGeometry)
    [:x, :y, :size, :color, :shape]
end


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
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGBA{Float32}[theme.default_color])
    default_aes.size = Measure[theme.default_point_size]
    aes = inherit(aes, default_aes)

    lw_hover_scale = 10
    lw_ratio = theme.line_width / aes.size[1]

    aes_x, aes_y = concretize(aes.x, aes.y)

    ctx = context()
    if aes.shape != nothing
        xs = Array(eltype(aes_x), 0)
        ys = Array(eltype(aes_y), 0)
        cs = Array(eltype(aes.color), 0)
        size = Array(eltype(aes.size), 0)
        shape_max = maximum(aes.shape)
        if shape_max > length(theme.shapes)
            error("Too many values for the shape aesthetic. Define more shapes in Theme.shapes")
        end

        for shape in 1:maximum(aes.shape)
            for (x, y, c, sz, sh) in Compose.cyclezip(aes.x, aes.y, aes.color,
                                                      aes.size, aes.shape)
                if sh == shape
                    push!(xs, x)
                    push!(ys, y)
                    push!(cs, c)
                    push!(size, sz)
                end
            end
            compose!(ctx, (context(), theme.shapes[shape](xs, ys, size), fill(cs)))
            empty!(xs)
            empty!(ys)
            empty!(cs)
            empty!(size)
        end
    else
        compose!(ctx,
            circle(aes.x, aes.y, aes.size, geom.tag),
            fill(aes.color))
    end
    compose!(ctx, linewidth(theme.highlight_width))

    if aes.color_key_continuous != nothing && aes.color_key_continuous
        compose!(ctx,
            stroke(map(theme.continuous_highlight_color, aes.color)))
    else
        stroke_colors =
            Gadfly.pooled_map(RGBA{Float32}, theme.discrete_highlight_color, aes.color)
        classes =
            Gadfly.pooled_map(Compat.ASCIIString,
                c -> svg_color_class_from_label(escape_id(aes.color_label([c])[1])),
                aes.color)

        compose!(ctx, stroke(stroke_colors), svgclass(classes))
    end

    return compose!(context(order=4), svgclass("geometry"), ctx)
end
