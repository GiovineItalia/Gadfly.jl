
using Hexagons

immutable HexagonalBinGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    tag::Symbol

    function HexagonalBinGeometry(
            default_statistic::Gadfly.StatisticElement;
            tag::Symbol=empty_tag)
        new(default_statistic, tag)
    end

    function HexagonalBinGeometry(; xbincount=200, ybincount=200, tag::Symbol=empty_tag)
        new(Gadfly.Stat.hexbin(xbincount=xbincount, ybincount=ybincount), tag)
    end
end


const hexbin = HexagonalBinGeometry


function default_statistic(geom::HexagonalBinGeometry)
    geom.default_statistic
end


function element_aesthetics(geom::HexagonalBinGeometry)
    [:x, :y, :xsize, :ysize, :color]
end


function render(geom::HexagonalBinGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGB{Float32}[theme.default_color])
    default_aes.xsize = [1.0]
    default_aes.ysize = [1.0]
    aes = inherit(aes, default_aes)

    Gadfly.assert_aesthetics_defined("Geom.hexbin", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.hexbin", aes, :x, :y)

    n = length(aes.x)
    visibility = Bool[!isna(c) for c in takestrict(cycle(aes.color), n)]
    xs = aes.x[visibility]
    ys = aes.y[visibility]
    xsizes = collect(eltype(aes.xsize), takestrict(cycle(aes.xsize), n))[visibility]
    ysizes = collect(eltype(aes.ysize), takestrict(cycle(aes.ysize), n))[visibility]
    cs = collect(eltype(aes.color), takestrict(cycle(aes.color), n))[visibility]
    n = length(xs)

    return compose!(
        context(),
        Compose.polygon([hexpoints(xs[i], ys[i], xsizes[i], ysizes[i]) for i in 1:n], geom.tag),
        linewidth(0.1mm), # pad the hexagons so they ovelap a little
        fill(cs),
        stroke(cs),
        svgclass("geometry"))
end
