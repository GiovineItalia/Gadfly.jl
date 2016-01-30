
immutable RibbonGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    tag::Symbol

    function RibbonGeometry(default_statistic=Gadfly.Stat.identity();
                            tag::Symbol=empty_tag)
        new(default_statistic, tag)
    end
end

const ribbon = RibbonGeometry


function default_statistic(geom::RibbonGeometry)
    return geom.default_statistic
end


function element_aesthetics(::RibbonGeometry)
    return [:x, :ymin, :ymax, :color]
end


function render(geom::RibbonGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, coord::Coord.cartesian)
    Gadfly.assert_aesthetics_defined("Geom.ribbon", aes, :x, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("Geom.ribbon", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGB{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    aes_x, aes_ymin, aes_ymax = concretize(aes.x, aes.ymin, aes.ymax)

    if length(aes.color) == 1 &&
        !(isa(aes.color, PooledDataArray) && length(levels(aes.color)) > 1)
        max_points = collect(zip(aes_x, aes_ymax))
        sort!(max_points, by=first)

        min_points = collect(zip(aes_x, aes_ymin))
        sort!(min_points, by=first, rev=true)

        ctx = compose!(
            context(),
            Compose.polygon(collect(chain(min_points, max_points))),
            fill(theme.lowlight_color(aes.color[1])))
    else
        XT, YT = eltype(aes_x), promote_type(eltype(aes_ymin), eltype(aes_ymax))
        max_points = Dict{RGB{Float32}, Vector{(@compat Tuple{XT, YT})}}()
        for (x, y, c) in zip(aes_x, aes_ymax, aes.color)
            if !haskey(max_points, c)
                max_points[c] = Array((@compat Tuple{XT, YT}), 0)
            end
            push!(max_points[c], (x, y))
        end

        min_points = Dict{RGB{Float32}, Vector{(@compat Tuple{XT, YT})}}()
        for (x, y, c) in zip(aes.x, aes.ymin, aes.color)
            if !haskey(min_points, c)
                min_points[c] = Array((@compat Tuple{XT, YT}), 0)
            end
            push!(min_points[c], (x, y))
        end

        for c in keys(max_points)
            sort!(max_points[c], by=first)
            sort!(min_points[c], by=first, rev=true)
        end

        ctx = compose!(
            context(),
            Compose.polygon([collect((@compat Tuple{XT, YT}), chain(min_points[c], max_points[c]))
                     for c in keys(max_points)], geom.tag),
            fill([theme.lowlight_color(c) for c in keys(max_points)]))
    end

    return compose!(
        ctx,
        svgclass("geometry"),
        stroke(nothing),
        linewidth(theme.line_width))
end
