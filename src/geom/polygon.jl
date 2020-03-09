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
`Theme.discrete_highlight_color`. If `fill=false` stroke the polygons using `Theme.lowlight_color` and `Theme.line_style`.
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
    default_aes.group = IndirectArray(fill(1,length(aes.x)))
    default_aes.color = fill(theme.default_color, length(aes.x))
    default_aes.linestyle = fill(1, length(aes.x))
    default_aes.alpha = fill(1, length(aes.x))
    aes = inherit(aes, default_aes)

    aes_x, aes_y, aes_color, aes_linestyle, aes_group, aes_alpha = concretize(aes.x, aes.y, aes.color, aes.linestyle, aes.group, aes.alpha)
    
    XT, YT, CT, GT, LST, AT = eltype(aes_x), eltype(aes_y), eltype(aes_color), eltype(aes_group), eltype(aes_linestyle), eltype(aes_alpha)

    groups = collect((Tuple{CT, GT, LST, AT}), zip(aes_color, aes_group, aes_linestyle, aes_alpha))
    ug = unique(groups)

    n = length(ug)
    polys = Vector{Vector{Tuple{XT,YT}}}(undef, n)
    θs = Vector{Float64}
    colors = Vector{CT}(undef, n)
    line_styles = Vector{LST}(undef, n)
    linestyle_palette_length = length(theme.line_style)
    alphas = Vector{Float64}(undef, n)
    alpha_discrete  = AT <: Int

    for (k,g) in enumerate(ug)
        i = groups.==[g]
        polys[k] = polygon_points(aes_x[i], aes_y[i], geom.preserve_order)
        colors[k] = first(aes_color[i])
        line_styles[k] = mod1(first(aes_linestyle[i]), linestyle_palette_length)
        alphas[k] = first(alpha_discrete ? theme.alphas[aes_alpha[i]] : aes_alpha[i])
    end
    
    plinestyles = Gadfly.get_stroke_vector.(theme.line_style[line_styles])
    pcolors = theme.lowlight_color.(colors)
    
    properties = geom.fill ? (fill(pcolors), stroke(theme.discrete_highlight_color.(colors)), fillopacity(alphas)) :
        (fill(nothing), stroke(pcolors), strokedash(plinestyles))                

    ctx = context(order=geom.order)
    compose!(ctx, Compose.polygon(polys, geom.tag), properties...)

    return compose!(ctx, linewidth(theme.line_width), svgclass("geometry"))
end
