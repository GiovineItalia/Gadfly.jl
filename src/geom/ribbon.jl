struct RibbonGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    fill::Bool
    tag::Symbol
end
RibbonGeometry(default_statistic=Gadfly.Stat.identity(); fill=true, tag=empty_tag) =
        RibbonGeometry(default_statistic, fill, tag)

"""
    Geom.ribbon[(; fill=true)]

Draw a ribbon at the positions in `x` bounded above and below by `ymax` and
`ymin`, respectively.  Optionally draw multiple ribbons by grouping with `color` and `alpha` (for `fill=true`),
 or `color` and `linestyle` (for `fill=false`).
"""
const ribbon = RibbonGeometry

default_statistic(geom::RibbonGeometry) = geom.default_statistic

element_aesthetics(::RibbonGeometry) = [:x, :ymin, :ymax, :color, :linestyle, :alpha]

function render(geom::RibbonGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.ribbon", aes, :x, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("Geom.ribbon", aes, element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.linestyle = fill(1, length(aes.x))
    default_aes.color = fill(theme.default_color, length(aes.x))
    default_aes.alpha = fill(1, length(aes.x))
    aes = inherit(aes, default_aes)

    aes_x, aes_ymin, aes_ymax, aes_color, aes_linestyle, aes_alpha =
         concretize(aes.x, aes.ymin, aes.ymax, aes.color, aes.linestyle, aes.alpha)
    XT, CT, LST, AT = eltype(aes_x), eltype(aes_color), eltype(aes_linestyle), eltype(aes_alpha)
    YT = Float64
    groups = collect((Tuple{CT, LST, AT}), zip(aes_color, aes_linestyle, aes_alpha))
    ug = unique(groups)
    
    V = Vector{Tuple{XT, YT}}
    K = Tuple{CT, LST, AT}

    max_points = Dict{K, V}(g=>V[] for g in ug)
    for (x, y, c, ls, a) in zip(aes_x, aes_ymax, aes_color, aes_linestyle, aes_alpha)
        push!(max_points[(c,ls,a)], (x, y))
    end

    min_points = Dict{K, V}(g=>V[] for g in ug)
    for (x, y, c, ls, a) in zip(aes_x, aes_ymin, aes_color, aes_linestyle, aes_alpha)
        push!(min_points[(c,ls,a)], (x, y))
    end

    for k in keys(max_points)
        sort!(max_points[k], by=first)
        sort!(min_points[k], by=first, rev=true)
    end

    kys = keys(max_points)
    polys = [collect(Tuple{XT, YT}, flatten((min_points[k], max_points[k]))) for k in kys]
    lines = [collect(Tuple{XT, YT}, flatten((min_points[k], [(last(min_points[k])[1], NaN)], max_points[k]))) for k in kys]

    n = length(kys)
    colors = Vector{Union{Colorant, String}}(undef, n)
    linestyles = Vector{Vector{Measure}}(undef, n)
    alphas = Vector{Float64}(undef, n)
    alpha_discrete  = AT <: Int

    for (i, (c,ls,a)) in enumerate(kys)
        colors[i] = theme.lowlight_color(c)
        linestyles[i] = Gadfly.get_stroke_vector(theme.line_style[ls])
        alphas[i] = alpha_discrete ? theme.alphas[a] : a
    end

    ctx = context()

    geom.fill ? compose!(ctx, Compose.polygon(polys, geom.tag), fill(colors), fillopacity(alphas)) : 
        compose!(ctx, Compose.line(lines, geom.tag), fill(nothing), stroke(colors), strokedash(linestyles))

    return compose!(ctx, svgclass("geometry"), linewidth(theme.line_width))
end
