using Hexagons

struct HexagonalBinGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    tag::Symbol
end
HexagonalBinGeometry(default_statistic; tag=empty_tag) =
        HexagonalBinGeometry(default_statistic, tag)
HexagonalBinGeometry(; xbincount=200, ybincount=200, tag=empty_tag) =
        HexagonalBinGeometry(Gadfly.Stat.hexbin(xbincount=xbincount, ybincount=ybincount), tag)

"""
    Geom.hexbin[(; xbincount=200, ybincount=200)]

Bin the `x` and `y` aesthetics into tiled hexagons and color by count.
`xbincount` and `ybincount` specify the number of bins.  This behavior relies
on the default use of [`Stat.hexbin`](@ref).

Alternatively, draw hexagons of size `xsize` and `ysize` at positions `x` and
`y` by passing [`Stat.identity`](@ref) to `plot` and manually binding the `color`
aesthetic.
"""
const hexbin = HexagonalBinGeometry

default_statistic(geom::HexagonalBinGeometry) = geom.default_statistic
element_aesthetics(geom::HexagonalBinGeometry) = [:x, :y, :xsize, :ysize, :color]

function render(geom::HexagonalBinGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGB{Float32}[theme.default_color])
    default_aes.xsize = [1.0]
    default_aes.ysize = [1.0]
    aes = inherit(aes, default_aes)

    Gadfly.assert_aesthetics_defined("Geom.hexbin", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.hexbin", aes, :x, :y)

    n = length(aes.x)
    visibility = Bool[!ismissing(c) for c in takestrict(cycle(aes.color), n)]
    xs = aes.x[visibility]
    ys = aes.y[visibility]
    xsizes = collect(eltype(aes.xsize), takestrict(cycle(aes.xsize), n))[visibility]
    ysizes = collect(eltype(aes.ysize), takestrict(cycle(aes.ysize), n))[visibility]
    cs = collect(eltype(aes.color), takestrict(cycle(aes.color), n))[visibility]
    n = length(xs)

    return compose!(
        context(),
        Compose.polygon([hexpoints(xs[i], ys[i], xsizes[i], ysizes[i]) for i in 1:n], geom.tag),
        fill(cs),
        svgclass("geometry"))
end
