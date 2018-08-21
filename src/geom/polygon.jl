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
Optionally plot multiple polygons according to the `group` or `color`
aesthetics.  `order` controls whether the polygon(s) are underneath or on top
of other forms.  If `fill` is true, fill and stroke the polygons according to
`Theme.discrete_highlight_color`, otherwise only stroke.  If `preserve_order`
is true, connect points in the order they are given, otherwise order the points
around their centroid.
"""
const polygon = PolygonGeometry

element_aesthetics(::PolygonGeometry) = [:x, :y, :color, :group]

"""
    Geom.ellipse[(; distribution=MvNormal, levels=[0.95], nsegments=51, fill=false)]

Draw a confidence ellipse, using a parametric multivariate distribution, for a
scatter of points specified by the `x` and `y` aesthetics.  Optionally plot
multiple ellipses according to the `group` or `color` aesthetics.  This
geometry is equivalent to [`Geom.polygon`](@ref) with [`Stat.ellipse`](@ref);
see the latter for more information.
"""
ellipse(; distribution::Type{<:ContinuousMultivariateDistribution}=MvNormal,
    levels::Vector=[0.95], nsegments::Int=51, fill::Bool=false) =
    PolygonGeometry(Gadfly.Stat.ellipse(distribution, levels, nsegments), preserve_order=true, fill=fill)

default_statistic(geom::PolygonGeometry) = geom.default_statistic


function polygon_points(xs, ys, preserve_order)
    T = (Tuple{eltype(xs), eltype(ys)})
    if preserve_order
        return T[(x, y) for (x, y) in zip(xs, ys)]
    else
        centroid_x, centroid_y = mean(xs), mean(ys)
        θ = atan2(xs - centroid_x, ys - centroid_y)
        perm = sortperm(θ)
        return T[(x, y) for (x, y) in zip(xs[perm], ys[perm])]
    end
end

# Render polygon geometry.
function render(geom::PolygonGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.polygon", aes, :x, :y)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGBA{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    ctx = context(order=geom.order)
    T = (eltype(aes.x), eltype(aes.y))

    line_style = Gadfly.get_stroke_vector(theme.line_style[1])

    if aes.group != nothing
        XT, YT = eltype(aes.x), eltype(aes.y)
        xs = DefaultDict{Any, Vector{XT}}(() -> XT[])
        ys = DefaultDict{Any, Vector{YT}}(() -> YT[])
        for (x, y, c, g) in zip(aes.x, aes.y, cycle(aes.color), cycle(aes.group))
            push!(xs[(c,g)], x)
            push!(ys[(c,g)], y)
        end

        compose!(ctx,
            Compose.polygon([polygon_points(xs[(c,g)], ys[(c,g)], geom.preserve_order)
                             for (c,g) in keys(xs)], geom.tag))
        cs = [c for (c,g) in keys(xs)]
        if geom.fill
            compose!(ctx, fill(cs),
                     stroke(map(theme.discrete_highlight_color, cs)))
        else
            compose!(ctx, fill(nothing), stroke(cs))
        end
    elseif length(aes.color) == 1 &&
            !(isa(aes.color, IndirectArray) && length(filter(!ismissing, aes.color.values)) > 1)
        compose!(ctx, Compose.polygon(polygon_points(aes.x, aes.y, geom.preserve_order), geom.tag))
        if geom.fill
            compose!(ctx, fill(aes.color[1]),
                     stroke(theme.discrete_highlight_color(aes.color[1])))
        else
            compose!(ctx, fill(nothing),
                     stroke(aes.color[1]))
        end
    else
        XT, YT = eltype(aes.x), eltype(aes.y)
        xs = DefaultDict{Color, Vector{XT}}(() -> XT[])
        ys = DefaultDict{Color, Vector{YT}}(() -> YT[])
        for (x, y, c) in zip(aes.x, aes.y, cycle(aes.color))
            push!(xs[c], x)
            push!(ys[c], y)
        end

        compose!(ctx,
            Compose.polygon([polygon_points(xs[c], ys[c], geom.preserve_order)
                             for c in keys(xs)], geom.tag))
        cs = collect(keys(xs))
        if geom.fill
            compose!(ctx, fill([theme.lowlight_color(c) for c in cs]),
                     stroke(map(theme.discrete_highlight_color, cs)))
        else
            compose!(ctx, fill(nothing), stroke(cs))
        end
    end

    return compose!(ctx, linewidth(theme.line_width), strokedash(line_style), svgclass("geometry"))
end
