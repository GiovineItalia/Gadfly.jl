using Compose: x_measure, y_measure

struct HBandGeometry <: Gadfly.GeometryElement
    color::Union{Vector, Color, (Void)}
    tag::Symbol

    HBandGeometry(color, tag) = new(color === nothing ? nothing : Gadfly.parse_colorant(color), tag)
end

HBandGeometry(; color = nothing, tag = empty_tag) = HBandGeometry(color, tag)

"""
    Geom.hband[(; color=nothing)]

Draw horizontal bands across the plot canvas with a vertical span specified by `ymin` and `ymax` aesthetics.

# Optional Aesthetics
- `color`:
  Default is `Theme.default_color`.
"""
const hband = HBandGeometry

element_aesthetics(::HBandGeometry) = [:ymin, :ymax]

# Generate a form for the hband geometry
function render(geom::HBandGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Geom.hband", aes, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("Geom.hband", aes, :ymin, :ymax)

    color = geom.color === nothing ? theme.default_color : geom.color

    x0 = fill(0w, length(aes.ymin))
    x1 = fill(1w, length(aes.ymin))

    ywidths = [(y1 - y0) * cy - theme.bar_spacing
               for (y0, y1) in zip(aes.ymin, aes.ymax)]

    root = compose(context(), svgclass("geometry"))

    compose!(root, (context(),
        rectangle(x0, aes.ymin, x1, ywidths, geom.tag),
        fill(color),
        stroke(nothing)))

    return root
end


struct VBandGeometry <: Gadfly.GeometryElement
    color::Union{Vector, Color, (Void)}
    tag::Symbol

    VBandGeometry(color, tag) = new(color === nothing ? nothing : Gadfly.parse_colorant(color), tag)
end

VBandGeometry(; color = nothing, tag = empty_tag) = VBandGeometry(color, tag)

"""
    Geom.vband[(; color=nothing)]

Draw vertical bands across the plot canvas with a horizontal span specified by `xmin` and `xmax` aesthetics.

# Optional Aesthetics
- `color`:
  Default is `Theme.default_color`.
"""
const vband = VBandGeometry

element_aesthetics(::VBandGeometry) = [:xmin, :xmax]

# Generate a form for the vband geometry
function render(geom::VBandGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Geom.vband", aes, :xmin, :xmax)
    Gadfly.assert_aesthetics_equal_length("Geom.vband", aes, :xmin, :xmax)

    color = geom.color === nothing ? theme.default_color : geom.color

    y0 = fill(0h, length(aes.xmin))
    y1 = fill(1h, length(aes.xmin))

    xwidths = [(x1 - x0) * cx - theme.bar_spacing
               for (x0, x1) in zip(aes.xmin, aes.xmax)]

    root = compose(context(), svgclass("geometry"))

    compose!(root, (context(),
        rectangle(aes.xmin, y0, xwidths, y1, geom.tag),
        fill(color),
        stroke(nothing)))

    return root
end
