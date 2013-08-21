
immutable RectangularBinGeometry <: Gadfly.GeometryElement
end


const rectbin = RectangularBinGeometry


function element_aesthetics(::RectangularBinGeometry)
    [:x, :y, :x_min, :x_max, :y_min, :y_max, :color]
end



# Render a rectbin geometry with continuous x_min/x_max y_min/y_max coordinates.
function render_continuous_rectbin(geom::RectangularBinGeometry,
                                   theme::Gadfly.Theme,
                                   aes::Gadfly.Aesthetics)
    n = length(aes.x_min)
    forms = Array(Compose.Form, 0)

    for (i, c) in zip(1:n, cycle(aes.color))
        if !isna(c)
            push!(forms, rectangle(aes.x_min[i], aes.y_min[i],
                                  (aes.x_max[i] - aes.x_min[i])*cx - theme.bar_spacing,
                                  (aes.y_max[i] - aes.y_min[i])*cy + theme.bar_spacing) <<
                             fill(c) << svgclass("geometry"))
        end
    end

    compose(combine(forms...),
            stroke(nothing),
            svgattribute("shape-rendering", "crispEdges"))
end


# Rendere a rectbin geometry with discrete x/y coordinaes.
function render_discrete_rectbin(geom::RectangularBinGeometry,
                                   theme::Gadfly.Theme,
                                   aes::Gadfly.Aesthetics)
    n = length(aes.x)
    forms = Array(Compose.Form, 0)
    for (i, c) in zip(1:n, cycle(aes.color))
        if !isna(c)
            x, y = aes.x[i], aes.y[i]
            push!(forms, compose(rectangle(x - 0.5, y - 0.5, 1.0, 1.0),
                                 fill(c),
                                 svgclass("geometry")))
        end
    end

    compose(combine(forms...),
            stroke(nothing),
            svgattribute("shape-rendering", "crispEdges"))
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

    if aes.x_min === nothing
        Gadfly.assert_aesthetics_defined("Geom.bar", aes, :x, :y)
        Gadfly.assert_aesthetics_equal_length("Geom.bar", aes, :x, :y)
        render_discrete_rectbin(geom, theme, aes)
    else
        Gadfly.assert_aesthetics_defined("Geom.bar",
                                         aes, :x_min, :x_max, :y_min, :y_max)
        Gadfly.assert_aesthetics_equal_length("Geom.bar",
                                              aes, :x_min, :x_max,
                                              :y_min, :y_max)
        render_continuous_rectbin(geom, theme, aes)
    end
end


function default_statistic(::RectangularBinGeometry)
    Gadfly.Stat.rectbin()
end


