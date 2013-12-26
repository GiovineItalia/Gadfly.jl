
using Hexagons

immutable HexagonalBinGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement

    function HexagonalBinGeometry(
            default_statistic::Gadfly.StatisticElement=Gadfly.Stat.identity())
        new(default_statistic)
    end

    function HexagonalBinGeometry()
        new(Gadfly.Stat.hexbin())
    end
end


const hexbin = HexagonalBinGeometry


function default_statistic(geom::HexagonalBinGeometry)
    geom.default_statistic
end


function element_aesthetics(geom::HexagonalBinGeometry)
    [:x, :y, :size, :color]
end


function render(geom::HexagonalBinGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    default_aes.size = [1.0]
    aes = inherit(aes, default_aes)

    Gadfly.assert_aesthetics_defined("Geom.hexbin", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.hexbin", aes, :x, :y)

    n = length(aes.x)

    forms = Array(Compose.Form, 0)
    for (i, c, s) in zip(1:n, cycle(aes.color), cycle(aes.size))
        if !isna(c)
            form = compose(polygon(hexpoints((aes.x[i], aes.y[i]), s)...),
                           fill(c))
            push!(forms, form)
        end
    end


    compose(combine(forms...),
            stroke(nothing),
            svgattribute("shape-rendering", "crispEdges"))
end


