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

# """
#     Geom.rect
#
# Draw colored rectangles with the corners specified by the
# `xmin`, `xmax`, `ymin` and `ymax` aesthetics.  Optionally
# specify their `color`.
# """
# rect() = RectangularBinGeometry(Gadfly.Stat.Identity())

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

    Gadfly.assert_aesthetics_defined("RectangularBinGeometry", aes, :xmin, :xmax, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("RectangularBinGeometry", aes, :xmin, :xmax, :ymin, :ymax)

    aes.xmax = x_measure(aes.xmax) .- theme.bar_spacing

    aes.ymax = y_measure(aes.ymax) .- theme.bar_spacing

    return render(RectangularGeometry(geom.default_statistic, geom.tag), theme, aes)
end
