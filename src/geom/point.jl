
# Geometry which displays points at given (x, y) positions.
immutable PointGeometry <: Gadfly.GeometryElement
    tag::Symbol

    function PointGeometry(; tag::Symbol=empty_tag)
        new(tag)
    end
end


const point = PointGeometry


function element_aesthetics(::PointGeometry)
    [:x, :y, :size, :color, :shape, :rho, :phi]
end


function element_coordinate_type(::PointGeometry, mapped_aesthetics)
    cartesian = :x in mapped_aesthetics && :y in mapped_aesthetics
    polar = :rho in mapped_aesthetics && :phi in mapped_aesthetics
    if cartesian && !polar
        return Coord.cartesian
    end
    if polar && ! cartesian
        return Coord.polar
    end
    error("Aesthetics (x, y) and (rho, phi) cannot be mixed.")
end


# Generate a form for a point geometry in cartesian coordinates.
#
# Args:
#   geom: point geometry.
#   theme: the plot's theme.
#   aes: aesthetics.
#   coord: coordinates.
#
# Returns:
#   A compose Form.
#
function render(geom::PointGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, coord::Coord.cartesian)
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
            Gadfly.pooled_map(ASCIIString,
                c -> svg_color_class_from_label(escape_id(aes.color_label([c])[1])),
                aes.color)

        compose!(ctx, stroke(stroke_colors), svgclass(classes))
    end

    return compose!(context(order=4), svgclass("geometry"), ctx)
end


# Generate a form for a point geometry in polar coordinates.
#
# Args:
#   geom: point geometry.
#   theme: the plot's theme.
#   aes: aesthetics.
#   coord: coordinates.
#
# Returns:
#   A compose Form.
#
function render(geom::PointGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, coord::Coord.polar)
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :rho, :phi)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGBA{Float32}[theme.default_color])
    default_aes.size = Measure[theme.default_point_size]
    aes = inherit(aes, default_aes)

    lw_hover_scale = 10
    lw_ratio = theme.line_width / aes.size[1]

    aes_rho, aes_phi = concretize(aes.rho, aes.phi)

    ctx = context()
    if aes.shape != nothing
        xs = Array(eltype(aes_rho), 0)
        ys = Array(eltype(aes_rho), 0)
        cs = Array(eltype(aes.color), 0)
        size = Array(eltype(aes.size), 0)
        shape_max = maximum(aes.shape)
        if shape_max > length(theme.shapes)
            error("Too many values for the shape aesthetic. Define more shapes in Theme.shapes")
        end

        for shape in 1:maximum(aes.shape)
            for (ρ, ϕ, c, sz, sh) in Compose.cyclezip(aes.rho, aes.phi, aes.color,
                                                      aes.size, aes.shape)
                if sh == shape
                    x, y = polar_to_cartesian(ρ, ϕ)
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
            circle([ρ * cos(ϕ) for (ρ, ϕ) in zip(aes.rho, aes.phi)],
                   [ρ * sin(ϕ) for (ρ, ϕ) in zip(aes.rho, aes.phi)],
                   aes.size, geom.tag),
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
            Gadfly.pooled_map(ASCIIString,
                c -> svg_color_class_from_label(escape_id(aes.color_label([c])[1])),
                aes.color)

        compose!(ctx, stroke(stroke_colors), svgclass(classes))
    end

    return compose!(context(order=4), svgclass("geometry"), ctx)
end
