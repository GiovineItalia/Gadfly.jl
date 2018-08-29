### should refactor to RectangleGeometry with Identity as the default Stat.
struct RectangularBinGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    tag::Symbol
end

function RectangularBinGeometry(
        default_statistic::Gadfly.StatisticElement=Gadfly.Stat.rectbin();
        tag=empty_tag)
    RectangularBinGeometry(default_statistic, tag)
end

"""
    Geom.rectbin

Draw equal sizes rectangles centered at `x` and `y` positions.  Optionally
specify their `color`.
"""
const rectbin = RectangularBinGeometry

"""
    Geom.rect

Draw colored rectangles with the corners specified by the
`xmin`, `xmax`, `ymin` and `ymax` aesthetics.  Optionally
specify their `color`.
"""
rect() = RectangularBinGeometry(Gadfly.Stat.Identity())

"""
    Geom.histogram2d[(; xbincount=nothing, xminbincount=3, xmaxbincount=150,
                        ybincount=nothing, yminbincount=3, ymaxbincount=150)]

Draw a heatmap of the `x` and `y` aesthetics by binning into rectangles and
indicating density with color.  This geometry is equivalent to
[`Geom.rect`](@ref) with [`Stat.histogram2d`](@ref);  see the latter for more
information.
"""
function histogram2d(; xbincount=nothing, xminbincount=3, xmaxbincount=150,
                       ybincount=nothing, yminbincount=3, ymaxbincount=150)
    RectangularBinGeometry(
        Gadfly.Stat.histogram2d(xbincount=xbincount,
                                xminbincount=xminbincount,
                                xmaxbincount=xmaxbincount,
                                ybincount=ybincount,
                                yminbincount=yminbincount,
                                ymaxbincount=ymaxbincount))
end

default_statistic(geom::RectangularBinGeometry) = geom.default_statistic

element_aesthetics(::RectangularBinGeometry) =
        [:x, :y, :xmin, :xmax, :ymin, :ymax, :color]

# Render rectangular bin (e.g., heatmap) geometry.
#
# Args:
#   geom: rectbin geometry
#   theme: the plot's theme
#   aes: some aesthetics
#
# Returns
#   A compose form.
#
function render(geom::RectangularBinGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGBA{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    Gadfly.assert_aesthetics_defined("RectangularBinGeometry", aes, :xmin, :xmax, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("RectangularBinGeometry", aes, :xmin, :xmax, :ymin, :ymax)

    nx = length(aes.xmin)
    ny = length(aes.ymin)
    n = nx

    xmin = aes.xmin
    xwidths = [(x1 - x0)*cx - theme.bar_spacing
               for (x0, x1) in zip(aes.xmin, aes.xmax)]

    ymin = aes.ymin
    ywidths = [(y1 - y0)*cy - theme.bar_spacing
               for (y0, y1) in zip(aes.ymin, aes.ymax)]

    if length(aes.color) == n
        cs = aes.color
    else
        cs = Array{RGBA{Float32}}(undef, n)
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

    return compose!(
        context(),
        rectangle(xmin, ymin, xwidths, ywidths, geom.tag),
        fill(cs),
        stroke(nothing),
        svgclass("geometry"),
        svgattribute("shape-rendering", "crispEdges"))
end
