struct PolygonGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    order::Int
    fill::Bool
    preserve_order::Bool
    tag::Symbol
end

PolygonGeometry(default_statistic=Gadfly.Stat.identity(); order=0, fill=false, preserve_order=false, tag=empty_tag) =
        PolygonGeometry(default_statistic, order, fill, preserve_order, tag)

"""
    Geom.polygon[(; order=0, fill=false, preserve_order=false)]

Draw polygons with vertices specified by the `x` and `y` aesthetics.
Optionally plot multiple polygons according to the `group`, `color`, `linestyle`, and/or `alpha`
aesthetics.  `order` controls whether the polygon(s) are underneath or on top
of other forms.  If `fill=true`, fill the polygons using `Theme.lowlight_color` and stroke the polygons using
`Theme.discrete_highlight_color`. If `fill=false` stroke the polygons using `Theme.lowlight_color`.
If `preserve_order=true` connect points in the order they are given, otherwise order the points
around their centroid.
"""
const polygon = PolygonGeometry

element_aesthetics(::PolygonGeometry) = [:x, :y, :color, :group, :linestyle, :alpha]

"""
    Geom.ellipse[(; distribution=MvNormal, levels=[0.95], nsegments=51, fill=false)]

Draw a confidence ellipse, using a parametric multivariate distribution, for a
scatter of points specified by the `x` and `y` aesthetics.  Optionally plot
multiple ellipses according to the `group` and/or `color` aesthetics. `levels` are auto-mapped to the `linestyle` aesthetic.
This geometry is equivalent to [`Geom.polygon`](@ref) with [`Stat.ellipse`](@ref);
see the latter for more information.
"""
ellipse(; distribution::Type{<:ContinuousMultivariateDistribution}=MvNormal,
    levels::Vector=[0.95], nsegments::Int=51, fill::Bool=false) =
    PolygonGeometry(Gadfly.Stat.ellipse(distribution, levels, nsegments), preserve_order=true, fill=fill)

default_statistic(geom::PolygonGeometry) = geom.default_statistic


function polygon_points(x::AbstractVector, y::AbstractVector, preserve_order::Bool)
    XT, YT = eltype(x), eltype(y)
    preserve_order && return collect(Tuple{XT,YT}, zip(x, y))
    p = sortperm(atan.(x.-mean(x), y.-mean(y)))
    return collect(Tuple{XT,YT}, zip(x, y))[p]
end

function render(geom::PolygonGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.polygon", aes, :x, :y)

    default_aes = Gadfly.Aesthetics()
    default_aes.group = IndirectArray([1])
    default_aes.color = Colorant[theme.default_color]
    default_aes.linestyle = [1]
    default_aes.alpha = [1]
    aes = inherit(aes, default_aes)

    aes_x, aes_y, aes_color, aes_linestyle, aes_group, aes_alpha = concretize(aes.x, aes.y, aes.color, aes.linestyle, aes.group, aes.alpha)

    XT, YT, CT, GT, LST, AT = eltype(aes_x), eltype(aes_y), eltype(aes_color), eltype(aes_group), eltype(aes_linestyle), eltype(aes_alpha)

    groups = collect((Tuple{CT, GT, LST, AT}), Compose.cyclezip(aes_color, aes_group, aes_linestyle, aes_alpha))
    ugroups = unique(groups)
    nugroups = length(ugroups)

    polys = Vector{Vector{Tuple{XT,YT}}}(undef, nugroups)
    colors = Vector{Colorant}(undef, nugroups)
    stroke_colors = Vector{Colorant}(undef, nugroups)
    linestyles = Vector{Vector{Measure}}(undef, nugroups)
    linestyle_palette_length = length(theme.line_style)
    alphas = Vector{Float64}(undef, nugroups)
    alpha_discrete  = AT <: Int
    linestyle_discrete = LST <: Int

    if nugroups==1
        polys[1] = polygon_points(aes_x, aes_y, geom.preserve_order)
    elseif nugroups>1
        for (k,g) in enumerate(ugroups)
            i = groups.==[g]
            polys[k] = polygon_points(aes_x[i], aes_y[i], geom.preserve_order)
        end
    end

    for (k, (c, g, ls, a)) in enumerate(ugroups)
        colors[k] = parse_colorant(theme.lowlight_color(c))
        stroke_colors[k] = parse_colorant(theme.discrete_highlight_color(c))
        linestyles[k] =  linestyle_discrete ? get_stroke_vector(theme.line_style[mod1(ls, linestyle_palette_length)]) : get_stroke_vector(ls)
        alphas[k] = alpha_discrete ? theme.alphas[a] : a
    end
    
    properties = geom.fill ? (fill(colors), stroke(stroke_colors), fillopacity(alphas), strokedash(linestyles)) :
        (fill(nothing), stroke(colors), strokedash(linestyles))

    ctx = context(order=geom.order)
    compose!(ctx, Compose.polygon(polys, geom.tag), properties...)

    return compose!(ctx, linewidth(theme.line_width), svgclass("geometry"))
end
