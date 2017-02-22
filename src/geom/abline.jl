
immutable ABLineGeometry <: Gadfly.GeometryElement
    color::@compat(Union{Vector, Color, (@compat Void)})
    size::@compat(Union{Vector, Measure, (@compat Void)})
    tag::Symbol
    T::String

    function ABLineGeometry(T; color::@compat(Union{Vector, String, Color, (@compat Void)})=nothing,
                           size::@compat(Union{Vector, Measure, (@compat Void)})=nothing,
                           tag::Symbol=empty_tag)
        new(color === nothing ? nothing :
                typeof(color)<:Vector ? [parse(Colorant,x) for x in color] :
                parse(Colorant, color),
            size, tag, T)
    end
end

abline(; args...) = ABLineGeometry("ab"; args...)
hline(; args...) = ABLineGeometry("h"; args...)
vline(; args...) = ABLineGeometry("v"; args...)

function element_aesthetics(geom::ABLineGeometry)
    geom.T=="ab" && return [:xintercept, :yintercept, :xslope, :yslope]
    geom.T=="h" && return [:yintercept]
    geom.T=="v" && return [:xintercept]
end

function render(geom::ABLineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    geom.T=="h" && Gadfly.assert_aesthetics_defined("ABLineGeometry", aes, :yintercept)
    geom.T=="v" && Gadfly.assert_aesthetics_defined("ABLineGeometry", aes, :xintercept)
    geom.T!="ab" && Gadfly.assert_aesthetics_undefined("ABLineGeometry", aes, :xslope, :yslope)

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
    line_style = Gadfly.get_stroke_vector(theme.line_style)

    function check_arguments(arg)
        if typeof(arg)<:Vector
            if length(arg)>1
                @assert length(arg) == length(aes.yintercept) + length(aes.xintercept)
            else
                arg = fill(arg[1], length(aes.yintercept) + length(aes.xintercept))
            end
        else
            arg = fill(arg, length(aes.yintercept) + length(aes.xintercept))
        end 
        arg
    end
    color = check_arguments(color)
    size = check_arguments(size)

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

    root = compose(context(), strokedash(line_style), svgclass("xfixed"))
    for (idx,(ylow,yhigh)) in enumerate(zip(ylows,yhighs))
        compose!(root, (context(),
                Compose.line([(low,ylow), (high,yhigh)], geom.tag),
                stroke(color[idx]),
                linewidth(size[idx])))
    end
    for (idx,(xlow,xhigh)) in enumerate(zip(xlows,xhighs))
        compose!(root, (context(),
                Compose.line([(xlow,low), (xhigh,high)], geom.tag),
                stroke(color[idx+length(ylows)]),
                linewidth(size[idx+length(ylows)])))
    end
    root
end
