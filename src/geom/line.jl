
# Line geometry connects (x, y) coordinates with lines.
immutable LineGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement

    # Do not reorder points along the x-axis.
    preserve_order::Bool

    order::Int

    function LineGeometry(default_statistic=Gadfly.Stat.identity();
                          preserve_order=false, order=2)
        new(default_statistic, preserve_order, order)
    end
end


const line = LineGeometry


function contour(; levels=15, samples=150, preserve_order=true)
    return LineGeometry(Gadfly.Stat.contour(levels=levels, samples=samples),
                                            preserve_order=preserve_order)
end


# Only allowing identity statistic in paths b/c I don't think any
# any of the others will work with `preserve_order=true` right now
function path()
    return LineGeometry(preserve_order=true)
end

function density()
    return LineGeometry(Gadfly.Stat.density())
end


function smooth(; method::Symbol=:loess, smoothing::Float64=0.75)
    return LineGeometry(Gadfly.Stat.smooth(method=method, smoothing=smoothing),
                        order=5)
end


function step(; direction::Symbol=:hv)
    return LineGeometry(Gadfly.Stat.step(direction=direction))
end


function default_statistic(geom::LineGeometry)
    return geom.default_statistic
end


function element_aesthetics(::LineGeometry)
    return [:x, :y, :color, :group]
end


# Render line geometry.
#
# Args:
#   geom: line geometry.
#   theme: the plot's theme.
#   aes: aesthetics.
#
# Returns:
#   A compose Form.
#
function render(geom::LineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.line", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.line", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGBA{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    ctx = context(order=geom.order)

    if aes.group != nothing
        # group points by group
        points = Dict{Any, Array{(Any, Any),1}}()
        for (x, y, c, g) in zip(aes.x, aes.y, cycle(aes.color), cycle(aes.group))
            if !haskey(points, (c,g))
                points[(c,g)] = Array((Any, Any),0)
            end
            push!(points[(c,g)], (x, y))
        end

        if !geom.preserve_order
            for (g, g_points) in points
                sort!(g_points, by=first)
            end
        end

        classes = [string("geometry ", svg_color_class_from_label(aes.color_label([c])[1]))
                   for (c, g) in keys(points)]

        ctx = compose!(ctx, Compose.line(collect(values(points))),
                      stroke(collect(map(first, keys(points)))),
                      svgclass(classes))

    elseif length(aes.color) == 1 &&
            !(isa(aes.color, PooledDataArray) && length(levels(aes.color)) > 1)
        T = (eltype(aes.x), eltype(aes.y))
        points = T[(x, y) for (x, y) in zip(aes.x, aes.y)]
        if !geom.preserve_order
            sort!(points, by=first)
        end

        ctx = compose!(ctx, Compose.line(points),
                       stroke(aes.color[1]),
                       svgclass("geometry"))
    else
        # group points by color
        points = Dict{ColorValue, Array{(Any, Any),1}}()
        for (x, y, c) in zip(aes.x, aes.y, cycle(aes.color))
            if !haskey(points, c)
                points[c] = Array((Any, Any),0)
            end
            push!(points[c], (x, y))
        end

        if !geom.preserve_order
            for (c, c_points) in points
                sort!(c_points, by=first)
            end
        end

        classes = [string("geometry ", svg_color_class_from_label(aes.color_label([c])[1]))
                   for c in keys(points)]

        ctx = compose!(ctx, Compose.line(collect(values(points))),
                      stroke(collect(keys(points))),
                      svgclass(classes))
    end

    return compose!(ctx, fill(nothing), linewidth(theme.line_width))
end


