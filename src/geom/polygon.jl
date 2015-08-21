
immutable PolygonGeometry <: Gadfly.GeometryElement
    order::Int
    fill::Bool
    preserve_order::Bool

    function PolygonGeometry(; order::Int=0, fill::Bool=false,
                               preserve_order::Bool=false)
        return new(order, fill, preserve_order)
    end
end


const polygon = PolygonGeometry


function element_aesthetics(::PolygonGeometry)
    return [:x, :y, :color, :group]
end


function polygon_points(xs, ys, preserve_order)
    T = (@compat Tuple{eltype(xs), eltype(ys)})
    if preserve_order
        return T[(x, y)for (x, y) in zip(xs, ys)]
    else
        centroid_x, centroid_y = mean(xs), mean(ys)
        θ = atan2(xs - centroid_x, ys - centroid_y)
        perm = sortperm(θ)
        return T[(x, y)for (x, y) in zip(xs[perm], ys[perm])]
    end
end


# Render polygon geometry.
function render(geom::PolygonGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.polygon", aes, :x, :y)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGBA{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    ctx = context(order=geom.order)
    T = (eltype(aes.x), eltype(aes.y))

    if aes.group != nothing
        XT, YT = eltype(aes.x), eltype(aes.y)
        xs = DefaultDict(Any, Vector{XT}, () -> XT[])
        ys = DefaultDict(Any, Vector{YT}, () -> YT[])
        for (x, y, c, g) in zip(aes.x, aes.y, cycle(aes.color), cycle(aes.group))
            push!(xs[(c,g)], x)
            push!(ys[(c,g)], y)
        end

        compose!(ctx,
            Compose.polygon([polygon_points(xs[(c,g)], ys[(c,g)], geom.preserve_order)
                             for (c,g) in keys(xs)]))
        cs = [c for (c,g) in keys(xs)]
        if geom.fill
            compose!(ctx, fill(cs),
                     stroke(map(theme.discrete_highlight_color, cs)))
        else
            compose!(ctx, fill(nothing), stroke(cs))
        end
    elseif length(aes.color) == 1 &&
            !(isa(aes.color, PooledDataArray) && length(levels(aes.color)) > 1)
        compose!(ctx, Compose.polygon(polygon_points(aes.x, aes.y, geom.preserve_order)))
        if geom.fill
            compose!(ctx, fill(aes.color[1]),
                     stroke(theme.discrete_highlight_color(aes.color[1])))
        else
            compose!(ctx, fill(nothing),
                     stroke(aes.color[1]))
        end
    else
        XT, YT = eltype(aes.x), eltype(aes.y)
        xs = DefaultDict(OpaqueColor, Vector{XT}, () -> XT[])
        ys = DefaultDict(OpaqueColor, Vector{YT}, () -> YT[])
        for (x, y, c) in zip(aes.x, aes.y, cycle(aes.color))
            push!(xs[c], x)
            push!(ys[c], y)
        end

        compose!(ctx,
            Compose.polygon([polygon_points(xs[c], ys[c], geom.preserve_order)
                             for c in keys(xs)]))
        cs = collect(keys(xs))
        if geom.fill
            compose!(ctx, fill(cs),
                     stroke(map(theme.discrete_highlight_color, cs)))
        else
            compose!(ctx, fill(nothing), stroke(cs))
        end
    end

    return compose!(ctx, linewidth(theme.line_width), svgclass("geometry"))
end

