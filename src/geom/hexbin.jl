
using Hexagons

immutable HexagonalBinGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement

    function HexagonalBinGeometry(
            default_statistic::Gadfly.StatisticElement=Gadfly.Stat.identity())
        new(default_statistic)
    end

    function HexagonalBinGeometry(; xbincount=50, ybincount=50)
        new(Gadfly.Stat.hexbin(xbincount=xbincount, ybincount=ybincount))
    end
end


const hexbin = HexagonalBinGeometry


function default_statistic(geom::HexagonalBinGeometry)
    geom.default_statistic
end


function element_aesthetics(geom::HexagonalBinGeometry)
    [:x, :y, :xsize, :ysize, :color]
end


function render(geom::HexagonalBinGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    default_aes.xsize = [1.0]
    default_aes.ysize = [1.0]
    aes = inherit(aes, default_aes)

    Gadfly.assert_aesthetics_defined("Geom.hexbin", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.hexbin", aes, :x, :y)

    n = length(aes.x)

    forms = Array(Compose.Form, 0)
    for (i, c, xs, ys) in zip(1:n, cycle(aes.color), cycle(aes.xsize), cycle(aes.ysize))
        if !isna(c)
            form = compose(polygon(hexpoints((aes.x[i], aes.y[i]), xs, ys)...),
                           linewidth(0.1mm), fill(c), stroke(c))
            push!(forms, form)
        end
    end


    compose(combine(forms...))
end


