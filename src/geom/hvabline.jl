function check_arguments(arg, len)
    if typeof(arg)<:Vector
        if length(arg)>1
            @assert length(arg) == len
        else
            arg = fill(arg[1], len)
        end
    else
        arg = fill(arg, len)
    end 
    arg
end

immutable HLineGeometry <: Gadfly.GeometryElement
    color::@compat(Union{Vector, Color, (@compat Void)})
    size::@compat(Union{Vector, Measure, (@compat Void)})
    style::@compat(Union{Vector, Symbol, (@compat Void)})
    tag::Symbol

    function HLineGeometry(; color::@compat(Union{Vector, String, Color, (@compat Void)})=nothing,
                           size::@compat(Union{Vector, Measure, (@compat Void)})=nothing,
                           style::@compat(Union{Vector, Symbol, (@compat Void)})=nothing,
                           tag::Symbol=empty_tag)
        new(color === nothing ? nothing :
                typeof(color)<:Vector ? [parse(Colorant,x) for x in color] :
                parse(Colorant, color),
            size, style, tag)
    end
end

const hline = HLineGeometry

function element_aesthetics(::HLineGeometry)
    [:yintercept]
end


# Generate a form for the hline geometry
function render(geom::HLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.hline", aes, :yintercept)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size
    style = geom.style === nothing ? theme.line_style : geom.style

    color = check_arguments(color, length(aes.yintercept))
    size = check_arguments(size, length(aes.yintercept))
    style = check_arguments(style, length(aes.yintercept))

    style = map(Gadfly.get_stroke_vector, style)

    root = compose(context(), svgclass("xfixed"))
    for (idx,y) in enumerate(aes.yintercept)
        compose!(root, (context(),
            Compose.line([(0w, y), (1w, y)], geom.tag),
            stroke(color[idx]),
            linewidth(size[idx]),
            strokedash(style[idx])))
    end
    root
end


immutable VLineGeometry <: Gadfly.GeometryElement
    color::@compat(Union{Vector, Color, (@compat Void)})
    size::@compat(Union{Vector, Measure, (@compat Void)})
    style::@compat(Union{Vector, Symbol, (@compat Void)})
    tag::Symbol

    function VLineGeometry(; color::@compat(Union{Vector, String, Color, (@compat Void)})=nothing,
                           size::@compat(Union{Vector, Measure, (@compat Void)})=nothing,
                           style::@compat(Union{Vector, Symbol, (@compat Void)})=nothing,
                           tag::Symbol=empty_tag)
        new(color === nothing ? nothing :
                typeof(color)<:Vector ? [parse(Colorant,x) for x in color] :
                parse(Colorant, color),
            size, style, tag)
    end
end

const vline = VLineGeometry


function element_aesthetics(::VLineGeometry)
    [:xintercept]
end

# Generate a form for the vline geometry
function render(geom::VLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.vline", aes, :xintercept)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size
    style = geom.style === nothing ? theme.line_style : geom.style

    color = check_arguments(color, length(aes.xintercept))
    size = check_arguments(size, length(aes.xintercept))
    style = check_arguments(style, length(aes.xintercept))

    style = map(Gadfly.get_stroke_vector, style)

    root = compose(context(), svgclass("xfixed"))
    for (idx,x) in enumerate(aes.xintercept)
        compose!(root, (context(),
                Compose.line([(x, 0h), (x, 1h)], geom.tag),
                stroke(color[idx]),
                linewidth(size[idx]),
                strokedash(style[idx])))
    end
    root
end


immutable ABLineGeometry <: Gadfly.GeometryElement
    color::@compat(Union{Vector, Color, (@compat Void)})
    size::@compat(Union{Vector, Measure, (@compat Void)})
    style::@compat(Union{Vector, Symbol, (@compat Void)})
    tag::Symbol

    function ABLineGeometry(; color::@compat(Union{Vector, String, Color, (@compat Void)})=nothing,
                           size::@compat(Union{Vector, Measure, (@compat Void)})=nothing,
                           style::@compat(Union{Vector, Symbol, (@compat Void)})=nothing,
                           tag::Symbol=empty_tag)
        new(color === nothing ? nothing :
                typeof(color)<:Vector ? [parse(Colorant,x) for x in color] :
                parse(Colorant, color),
            size, style, tag)
    end
end

abline = ABLineGeometry

function element_aesthetics(geom::ABLineGeometry)
    [:xintercept, :yintercept, :xslope, :yslope]
end
function render(geom::ABLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    function check_aesthetics(intercept, slope)
        if getfield(aes, intercept) == nothing
            getfield(aes, slope) == nothing || error()
            setfield!(aes, intercept, [])
            setfield!(aes, slope, [])
        else
            if getfield(aes, slope) == nothing
                setfield!(aes, slope, fill(0, length(getfield(aes,intercept))))
            else
                @assert length(getfield(aes, intercept)) == length(getfield(aes, slope))
            end
        end
    end
    check_aesthetics(:xintercept, :yslope)
    check_aesthetics(:yintercept, :xslope)

    color = geom.color === nothing ? theme.default_color : geom.color
    size = geom.size === nothing ? theme.line_width : geom.size
    style = geom.style === nothing ? theme.line_style : geom.style

    color = check_arguments(color, length(aes.yintercept) + length(aes.xintercept))
    size = check_arguments(size, length(aes.yintercept) + length(aes.xintercept))
    style = check_arguments(style, length(aes.yintercept) + length(aes.xintercept))

    style = map(Gadfly.get_stroke_vector, style)

    # it would've been nice to just say low, high = realmin(Float64), realmax(Float64).
    # but SVG() and PDF() have silent overflow errors when plotting way outside the context's
    # bounding box.  so instead, use the extrema of the data, and widen a bit to make sure
    # the line extends to the edges of the graph.

    if typeof(aes.y) <: Array{Function}
        low, high = aes.xmin[1], aes.xmax[1]
    else
        xextrema = extrema(aes.x)
        yextrema = extrema(aes.y)
        low = min(xextrema[1], yextrema[1])
        high = max(xextrema[2], yextrema[2])
    end

    range = high-low
    low -= range
    high += range

    ylows  = [ low * m + b for (m,b) in zip(aes.xslope, aes.yintercept)]
    yhighs = [high * m + b for (m,b) in zip(aes.xslope, aes.yintercept)]
    xlows  = [ low * m + b for (m,b) in zip(aes.yslope, aes.xintercept)]
    xhighs = [high * m + b for (m,b) in zip(aes.yslope, aes.xintercept)]

    root = compose(context(), svgclass("xfixed"))
    for (idx,(ylow,yhigh)) in enumerate(zip(ylows,yhighs))
        compose!(root, (context(),
                Compose.line([(low,ylow), (high,yhigh)], geom.tag),
                stroke(color[idx]),
                linewidth(size[idx]),
                strokedash(style[idx])))
    end
    for (idx,(xlow,xhigh)) in enumerate(zip(xlows,xhighs))
        compose!(root, (context(),
                Compose.line([(xlow,low), (xhigh,high)], geom.tag),
                stroke(color[idx+length(ylows)]),
                linewidth(size[idx+length(ylows)]),
                strokedash(style[idx+length(ylows)])))
    end
    root
end
