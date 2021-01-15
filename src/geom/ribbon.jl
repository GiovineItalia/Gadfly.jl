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
    Gadfly.assert_aesthetics_equal_length("Geom.ribbon", aes, :x, :ymin, :ymax)

    default_aes = Gadfly.Aesthetics()
    default_aes.linestyle = [1]
    default_aes.color = Colorant[theme.default_color]
    default_aes.alpha = [1]
    aes = inherit(aes, default_aes)

    aes_x, aes_ymin, aes_ymax, aes_color, aes_linestyle, aes_alpha =
         concretize(aes.x, aes.ymin, aes.ymax, aes.color, aes.linestyle, aes.alpha)
    XT, CT, LST, AT = eltype(aes_x), eltype(aes_color), eltype(aes_linestyle), eltype(aes_alpha)
    YT = eltype(aes_ymin)
    groups = collect((Tuple{CT, LST, AT}), Compose.cyclezip(aes_color, aes_linestyle, aes_alpha))
    ugroups = unique(groups)
    nugroups = length(ugroups)
    
    V = Vector{Tuple{XT, YT}}
    K = Tuple{CT, LST, AT}

    max_points = Dict{K, V}(g=>V[] for g in ugroups)
    min_points = Dict{K, V}(g=>V[] for g in ugroups)
    for (x, ymin, ymax, c, ls, a) in Compose.cyclezip(aes_x, aes_ymin, aes_ymax, aes_color, aes_linestyle, aes_alpha)
        push!(max_points[(c,ls,a)], (x, ymax))
        push!(min_points[(c,ls,a)], (x, ymin))
    end

    for k in keys(max_points)
        sort!(max_points[k], by=first)
        sort!(min_points[k], by=first, rev=true)
    end

    kys = keys(max_points)
    polys = [collect(Tuple{XT, YT}, Iterators.flatten((min_points[k], max_points[k]))) for k in kys]
    lines = [collect(Tuple{XT, Union{YT, Missing}}, Iterators.flatten((min_points[k], [(last(min_points[k])[1], missing)], max_points[k]))) for k in kys]

    colors = Vector{Colorant}(undef, nugroups)
    linestyles = Vector{Vector{Measure}}(undef, nugroups)
    linestyle_palette_length = length(theme.line_style)
    alphas = Vector{Float64}(undef, nugroups)
    alpha_discrete  = AT <: Int
    linestyle_discrete = LST <: Int

    for (i, (c,ls,a)) in enumerate(kys)
        colors[i] = parse_colorant(theme.lowlight_color(c))
        linestyles[i] = linestyle_discrete ? get_stroke_vector(theme.line_style[mod1(ls, linestyle_palette_length)]) : get_stroke_vector(ls)
        alphas[i] = alpha_discrete ? theme.alphas[a] : a
    end

    ctx = context()

    geom.fill ? compose!(ctx, Compose.polygon(polys, geom.tag), fill(colors), fillopacity(alphas)) :
        compose!(ctx, Compose.line(lines, geom.tag), stroke(colors), strokedash(linestyles))

    return compose!(ctx, svgclass("geometry"), linewidth(theme.line_width))
end
