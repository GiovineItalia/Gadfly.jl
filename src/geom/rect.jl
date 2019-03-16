using Compose: x_measure, y_measure

struct RectangularGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    tag::Symbol
end

function RectangularGeometry(
        default_statistic::Gadfly.StatisticElement=Gadfly.Stat.identity();
        tag=empty_tag)
    RectangularGeometry(default_statistic, tag)
end

"""
    Geom.rect

Draw colored rectangles with the corners specified by the
`xmin`, `xmax`, `ymin` and `ymax` aesthetics.  Optionally
specify their `color`.
"""
const rect = RectangularGeometry

default_statistic(geom::RectangularGeometry) = geom.default_statistic

element_aesthetics(::RectangularGeometry) =
        [:xmin, :xmax, :ymin, :ymax, :color]

# Render rectangle geometry.
#
# Args:
#   geom: rect geometry
#   theme: the plot's theme
#   aes: some aesthetics
#
# Returns
#   A compose form.
#
function render(geom::RectangularGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGBA{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    Gadfly.assert_aesthetics_defined("RectangularGeometry", aes, :xmin, :xmax, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("RectangularGeometry", aes, :xmin, :xmax, :ymin, :ymax)

    xmin = aes.xmin
    xmax = aes.xmax
    ymin = aes.ymin
    ymax = aes.ymax

    n = length(xmin)

    if length(aes.color) == n
        cs = aes.color
    else
        cs = Vector{RGBA{Float32}}(undef, n)
        for i in 1:n
            cs[i] = aes.color[((i - 1) % length(aes.color)) + 1]
        end
    end

    allvisible = true
    for c in cs
        if c == nothing
            allvisible = false
            break
        end
    end

    if !allvisible
        visibility = cs .!= nothing
        cs = cs[visibility]
        xmin = xmin[visibility]
        xmax = xmax[visibility]
        ymin = ymin[visibility]
        ymax = ymax[visibility]
    end

    polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, length(xmin))
    for i in 1:length(xmin)
        x0 = x_measure(xmin[i])
        x1 = x_measure(xmax[i])
        y0 = y_measure(ymin[i])
        y1 = y_measure(ymax[i])
        polys[i] = Tuple{Measure, Measure}[(x0, y0), (x0, y1), (x1, y1), (x1, y0)]
    end

    return compose!(
        context(),
        Compose.polygon(polys),
        fill(cs),
        stroke(nothing),
        svgclass("geometry"),
        svgattribute("shape-rendering", "crispEdges"))
end
