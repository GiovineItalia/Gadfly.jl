
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
    [:x, :y, :x_min, :x_max, :y_min, :y_max, :color]
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

    if aes.x === nothing && (aes.x_min === nothing || aes.x_max === nothing)
        error("Geom.rectbin requires either x or both x_min and x_max be defined.")
    end

    if aes.y === nothing && (aes.y_min === nothing || aes.y_max === nothing)
        error("Geom.rectbin requires either y or both y_min and y_max be defined.")
    end

    if aes.x_min != nothing && length(aes.x_min) != length(aes.x_max)
        error("Geom.rectbin requires that x_min and x_max be of equal length.")
    end

    if aes.y_min != nothing && length(aes.y_min) != length(aes.y_max)
        error("Geom.rectbin requires that y_min and y_max be of equal length.")
    end

    nx = aes.x_min === nothing ? length(aes.x) : length(aes.x_min)
    ny = aes.y_min === nothing ? length(aes.y) : length(aes.y_min)

    if nx != ny
        error("""Geom.rectbin requires an equal number of x (or x_min/x_max) and
                 y (or y_min/y_max) values.""")
    end

    if aes.x_min === nothing
        x_min = aes.x - 0.5
        x_max = aes.x + 0.5
    else
        x_min = aes.x_min
        x_max = aes.x_max
    end

    if aes.y_min === nothing
        y_min = aes.y - 0.5
        y_max = aes.y + 0.5
    else
        y_min = aes.y_min
        y_max = aes.y_max
    end

    n = nx
    forms = Array(Compose.Form, 0)
    for (i, c) in zip(1:n, cycle(aes.color))
        if !isna(c)
            form = compose(rectangle(x_min[i], y_min[i],
                                    (x_max[i] - x_min[i])*cx - theme.bar_spacing,
                                    (y_max[i] - y_min[i])*cy - theme.bar_spacing),
                           fill(c), svgclass("geometry"))

            push!(forms, form)
        end
    end

    compose(combine(forms...),
            stroke(nothing),
            svgattribute("shape-rendering", "crispEdges"))
end


