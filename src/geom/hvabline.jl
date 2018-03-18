using Compose: x_measure, y_measure

function check_arguments(arg::Vector, len)
    if length(arg)>1
        @assert length(arg) == len
    else
        arg = fill(arg[1], len)
    end
    arg
end
check_arguments(arg, len) = fill(arg, len)


struct HLineGeometry <: Gadfly.GeometryElement
    color::Union{Vector, Color, (Nothing)}
    size::Union{Vector, Measure, (Nothing)}
    style::Union{Vector, Symbol, (Nothing)}
    tag::Symbol

    HLineGeometry(color, size, style, tag) =
            new(color === nothing ? nothing : Gadfly.parse_colorant(color), size, style, tag)
end
HLineGeometry(; color=nothing, size=nothing, style=nothing, tag=empty_tag) =
        HLineGeometry(color, size, style, tag)

"""
    Geom.hline[(; color=nothing, size=nothing, style=nothing)]

Draw horizontal lines across the plot canvas at each position in the `yintercept` aesthetic.
"""
const hline = HLineGeometry

element_aesthetics(::HLineGeometry) = [:yintercept]

# Generate a form for the hline geometry
function render(geom::HLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.hline", aes, :yintercept)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size
    style = geom.style === nothing ? theme.line_style[1] : geom.style

    color = check_arguments(color, length(aes.yintercept))
    size = check_arguments(size, length(aes.yintercept))
    style = check_arguments(style, length(aes.yintercept))

    style = map(Gadfly.get_stroke_vector, style)

    root = compose(context(), svgclass("xfixed"))
    for (idx,y) in enumerate(aes.yintercept)
        compose!(root, (context(),
            Compose.line([(0w, y_measure(y)), (1w, y_measure(y))], geom.tag),
            stroke(color[idx]),
            linewidth(size[idx]),
            strokedash(style[idx])))
    end
    root
end


struct VLineGeometry <: Gadfly.GeometryElement
    color::Union{Vector, Color, (Nothing)}
    size::Union{Vector, Measure, (Nothing)}
    style::Union{Vector, Symbol, (Nothing)}
    tag::Symbol

    VLineGeometry(color, size, style, tag) =
            new(color === nothing ? nothing : Gadfly.parse_colorant(color), size, style, tag)
end
VLineGeometry(; color=nothing, size=nothing, style=nothing, tag=empty_tag) =
        VLineGeometry(color, size, style, tag)

"""
    Geom.vline[(; color=nothing, size=nothing, style=nothing)]

Draw vertical lines across the plot canvas at each position in the `xintercept` aesthetic.
"""
const vline = VLineGeometry

element_aesthetics(::VLineGeometry) = [:xintercept]

# Generate a form for the vline geometry
function render(geom::VLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.vline", aes, :xintercept)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size
    style = geom.style === nothing ? theme.line_style[1] : geom.style

    color = check_arguments(color, length(aes.xintercept))
    size = check_arguments(size, length(aes.xintercept))
    style = check_arguments(style, length(aes.xintercept))

    style = map(Gadfly.get_stroke_vector, style)

    root = compose(context(), svgclass("yfixed"))
    for (idx,x) in enumerate(aes.xintercept)
        compose!(root, (context(),
                Compose.line([(x_measure(x), 0h), (x_measure(x), 1h)], geom.tag),
                stroke(color[idx]),
                linewidth(size[idx]),
                strokedash(style[idx])))
    end
    root
end


struct ABLineGeometry <: Gadfly.GeometryElement
    color::Union{Vector, Color, (Nothing)}
    size::Union{Vector, Measure, (Nothing)}
    style::Union{Vector, Symbol, (Nothing)}
    tag::Symbol

    ABLineGeometry(color, size, style, tag) =
            new(color === nothing ? nothing : Gadfly.parse_colorant(color), size, style, tag)
end
ABLineGeometry(; color=nothing, size=nothing, style=nothing, tag::Symbol=empty_tag) =
        ABLineGeometry(color, size, style, tag)

"""
    Geom.abline[(; color=nothing, size=nothing, style=nothing)]

For each corresponding pair of elements in the `intercept` and `slope` aesthetics,
draw the lines `T(y) = slope * T(x) + intercept` across the plot canvas, where `T(⋅)` defaults to the identity function.
If unspecified, `intercept` defaults to [0] and `slope` to [1].

This geometry also works with nonlinear `Scale` transformations of the `y` and/or `x` variable, with one caveat: for log transformations of the `x` variable, the `intercept` is the `y`-value at `x=1` rather than at `x=0`. 
"""
const abline = ABLineGeometry

element_aesthetics(geom::ABLineGeometry) = [:intercept, :slope]

function render(geom::ABLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    if aes.intercept == nothing && aes.slope == nothing
        aes.intercept = [0]
        aes.slope = [1]
    elseif aes.intercept == nothing
        aes.intercept = fill(0,length(aes.slope))
    elseif aes.slope == nothing
        aes.slope = fill(1,length(aes.intercept))
    end
    Gadfly.assert_aesthetics_equal_length("Geom.line", aes, element_aesthetics(geom)...)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size
    style = geom.style === nothing ? theme.line_style[1] : geom.style

    color = check_arguments(color, length(aes.intercept))
    size = check_arguments(size, length(aes.intercept))
    style = check_arguments(style, length(aes.intercept))

    style = map(Gadfly.get_stroke_vector, style)

    # it would've been nice to just say x0, x1 = realmin(Float64), realmax(Float64).
    # but SVG() and PDF() have silent overflow errors when plotting way outside the
    # context's bounding box.  so instead, use the extrema of the data, and hope that
    # the line extends to the edges of the graph.

    if typeof(aes.y) <: Array{Function}
        lowx, highx = aes.xmin[1], aes.xmax[1]
    else
        lowx, highx = extrema(aes.x)
    end

    # extending the line to width 3 times x-range of data should be enough
    rangex = highx - lowx
    x0 = lowx - rangex
    x1 = highx + rangex

    y0s = [x0 * m + b for (m,b) in zip(aes.slope, aes.intercept)]
    y1s = [x1 * m + b for (m,b) in zip(aes.slope, aes.intercept)]

    root = compose(context(), svgclass("geometry"))
    for (idx,(y0,y1)) in enumerate(zip(y0s,y1s))
        compose!(root, (context(),
                Compose.line([(x_measure(x0),y_measure(y0)),
                              (x_measure(x1),y_measure(y1))], geom.tag),
                stroke(color[idx]),
                linewidth(size[idx]),
                strokedash(style[idx])))
    end
    root
end
