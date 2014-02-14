
# Line geometry connects (x, y) coordinates with lines.
immutable LineGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement

    # Do not reorder points along the x-axis.
    preserve_order::Bool

    function LineGeometry(default_statistic=Gadfly.Stat.identity();
                          preserve_order=false)
        new(default_statistic, preserve_order)
    end
end


const line = LineGeometry


function density()
    return LineGeometry(Gadfly.Stat.density())
end


function smooth(; smoothing::Float64=0.75)
    return LineGeometry(Gadfly.Stat.smooth(smoothing=smoothing))
end


function step(; direction::Symbol=:hv)
    return LineGeometry(Gadfly.Stat.step(direction=direction))
end


function default_statistic(geom::LineGeometry)
    return geom.default_statistic
end


function element_aesthetics(::LineGeometry)
    return [:x, :y, :color]
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
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    aes = inherit(aes, default_aes)

    if length(aes.color) == 1 &&
        !(isa(aes.color, PooledDataArray) && length(levels(aes.color)) > 1)
        points = {(x, y) for (x, y) in zip(aes.x, aes.y)}
        if !geom.preserve_order
            sort!(points, by=first)
        end
        form = compose(lines(points...),
                       stroke(aes.color[1]),
                       svgclass("geometry"))
    else
        # group points by color
        points = Dict{ColorValue, Array{(Float64, Float64),1}}()
        for (x, y, c) in zip(aes.x, aes.y, cycle(aes.color))
            if !haskey(points, c)
                points[c] = Array((Float64, Float64),0)
            end
            push!(points[c], (x, y))
        end

        forms = Array(Any, length(points))
        for (i, (c, c_points)) in enumerate(points)
            if !geom.preserve_order
                sort!(c_points, by=first)
            end
            forms[i] =
                compose(lines({(x, y) for (x, y) in c_points}...),
                        stroke(c),
                        svgclass(@sprintf("geometry color_%s",
                                          escape_id(aes.color_label([c])[1]))))
        end
        form = combine(forms...)
    end

    compose(form, fill(nothing), linewidth(theme.line_width))
end


