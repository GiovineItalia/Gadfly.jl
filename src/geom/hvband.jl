using Compose: x_measure, y_measure

# Band geometry summarizes data as vertical or horizontal bands.
struct BandGeometry <: Gadfly.GeometryElement
    orientation::Symbol
    color::Union{Vector, Color, (Void)}
    tag::Symbol
    BandGeometry(orientation, color, tag) = new(orientation, color === nothing ? nothing : Gadfly.parse_colorant(color), tag)
end


HBandGeometry(; color = nothing, tag = empty_tag) = BandGeometry(:horizontal, color, tag)

"""
    Geom.hband[(; color=nothing)]

Draw horizontal bands across the plot canvas with a vertical span specified by `ymin` and `ymax` aesthetics.

# Optional Aesthetics
- `color`:
  Default is `Theme.default_color`.
"""
const hband = HBandGeometry


VBandGeometry(; color = nothing, tag = empty_tag) = BandGeometry(:vertical, color, tag)

"""
    Geom.vband[(; color=nothing)]

Draw vertical bands across the plot canvas with a horizontal span specified by `xmin` and `xmax` aesthetics.

# Optional Aesthetics
- `color`:
  Default is `Theme.default_color`.
"""
const vband = VBandGeometry


element_aesthetics(geom::BandGeometry) = geom.orientation == :vertical ?
            [:xmin, :xmax, :color] : [:ymin, :ymax, :color]

            
# Generate a form for the bad geometry
#
# Args:
#   geom: band geometry.
#   theme: the plot's theme.
#   aes: aesthetics.
#
# Returns:
#   A compose Form.
#
function render(geom::BandGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    if geom.orientation == :horizontal
        Gadfly.assert_aesthetics_defined("BandGeometry", aes, :ymin, :ymax)
        Gadfly.assert_aesthetics_equal_length("BandGeometry", aes, :ymin, :ymax)

        n = max(length(aes.ymin)) #Note: already passed check for equal lengths.

        aes.xmin = fill(0w, n)
        xwidths = fill(1w, n)

        ywidths = [(y1 - y0) * cy
                   for (y0, y1) in zip(aes.ymin, aes.ymax)]

    elseif geom.orientation == :vertical
        Gadfly.assert_aesthetics_defined("BandGeometry", aes, :xmin, :xmax)
        Gadfly.assert_aesthetics_equal_length("BandGeometry", aes, :xmin, :xmax)

        n = max(length(aes.xmin)) #Note: already passed check for equal lengths.

        aes.ymin = fill(0h, n)
        ywidths = fill(1h, n)

        xwidths = [(x1 - x0) * cx
                   for (x0, x1) in zip(aes.xmin, aes.xmax)]
    else
        error("Orientation must be :horizontal or :vertical")
    end

    color = geom.color === nothing ? theme.default_color : geom.color

    return compose!(
        context(),
        rectangle(aes.xmin, aes.ymin, xwidths, ywidths, geom.tag),
        fill(color),
        stroke(nothing),
        svgclass("geometry"),
        svgattribute("shape-rendering", "crispEdges"))

end
