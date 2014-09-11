
immutable RectangularBinGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement

    function RectangularBinGeometry(
            default_statistic::Gadfly.StatisticElement=Gadfly.Stat.identity())
        new(default_statistic)
    end
end


const rectbin = RectangularBinGeometry


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


function default_statistic(geom::RectangularBinGeometry)
    geom.default_statistic
end


function element_aesthetics(::RectangularBinGeometry)
    [:x, :y, :xmin, :xmax, :ymin, :ymax, :color]
end


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
function render(geom::RectangularBinGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, data::Gadfly.Data,
                scales::Dict{Symbol, ScaleElement})

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGB{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    if aes.x === nothing && (aes.xmin === nothing || aes.xmax === nothing)
        error("Geom.rectbin requires either x or both xmin and xmax be defined.")
    end

    if aes.y === nothing && (aes.ymin === nothing || aes.ymax === nothing)
        error("Geom.rectbin requires either y or both ymin and ymax be defined.")
    end

    if aes.xmin != nothing && length(aes.xmin) != length(aes.xmax)
        error("Geom.rectbin requires that xmin and xmax be of equal length.")
    end

    if aes.ymin != nothing && length(aes.ymin) != length(aes.ymax)
        error("Geom.rectbin requires that ymin and ymax be of equal length.")
    end

    nx = aes.xmin === nothing ? length(aes.x) : length(aes.xmin)
    ny = aes.ymin === nothing ? length(aes.y) : length(aes.ymin)

    if nx != ny
        error("""Geom.rectbin requires an equal number of x (or xmin/xmax) and
                 y (or ymin/ymax) values.""")
    end
    n = nx

    if aes.xmin === nothing
        xmin = [x - 0.5 for x in aes.x]
        xwidths = [1.0*cx - theme.bar_spacing]
    else
        xmin = aes.xmin
        xwidths = [(x1 - x0)*cx - theme.bar_spacing
                   for (x0, x1) in zip(aes.xmin, aes.xmax)]
    end

    if aes.ymin === nothing
        ymin = [y - 0.5 for y in aes.y]
        ywidths = [1.0*cy - theme.bar_spacing]
    else
        ymin = aes.ymin
        ywidths = [(y1 - y0)*cy - theme.bar_spacing
                   for (y0, y1) in zip(aes.ymin, aes.ymax)]
    end

    if length(aes.color) == n
        cs = aes.color
    else
        cs = Array(RGB{Float32}, n)
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
        rectangle(xmin, ymin, xwidths, ywidths),
        fill(cs),
        stroke(nothing),
        svgclass("geometry"),
        svgattribute("shape-rendering", "crispEdges"))
end


