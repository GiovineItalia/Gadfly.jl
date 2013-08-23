
immutable RectangularBinGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement

    function RectangularBinGeometry(
            default_statistic::Gadfly.StatisticElement=Gadfly.Stat.identity())
        new(default_statistic)
    end
end


const rectbin = RectangularBinGeometry


function histogram2d()
    RectangularBinGeometry(Gadfly.Stat.histogram2d())
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
function render(geom::RectangularBinGeometry,
                theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
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

    if aes.xmin === nothing
        xmin = aes.x - 0.5
        xmax = aes.x + 0.5
    else
        xmin = aes.xmin
        xmax = aes.xmax
    end

    if aes.ymin === nothing
        ymin = aes.y - 0.5
        ymax = aes.y + 0.5
    else
        ymin = aes.ymin
        ymax = aes.ymax
    end

    n = nx
    forms = Array(Compose.Form, 0)
    for (i, c) in zip(1:n, cycle(aes.color))
        if !isna(c)
            form = compose(rectangle(xmin[i], ymin[i],
                                    (xmax[i] - xmin[i])*cx - theme.bar_spacing,
                                    (ymax[i] - ymin[i])*cy - theme.bar_spacing),
                           fill(c), svgclass("geometry"))

            push!(forms, form)
        end
    end

    compose(combine(forms...),
            stroke(nothing),
            svgattribute("shape-rendering", "crispEdges"))
end


