
immutable RibbonGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement

    function RibbonGeometry(default_statistic=Gadfly.Stat.identity())
        new(default_statistic)
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
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    Gadfly.assert_aesthetics_defined("Geom.ribbon", aes, :x, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("Geom.ribbon", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    aes = inherit(aes, default_aes)

    if length(aes.color) == 1 &&
        !(isa(aes.color, PooledDataArray) && length(levels(aes.color)) > 1)
        max_points = collect((Any, Any), zip(aes.x, aes.ymax))
        sort!(max_points, by=first)

        min_points = collect((Any, Any), zip(aes.x, aes.ymin))
        sort!(min_points, by=first, rev=true)

        ctx = compose!(
            context(),
            polygon(collect((Any, Any), chain(min_points, max_points))),
            fill(theme.lowlight_color(aes.color[1])))
    else
        max_points = Dict{ColorValue, Array{(Any, Any), 1}}()
        for (x, y, c) in zip(aes.x, aes.ymax, aes.color)
            if !haskey(max_points, c)
                max_points[c] = Array((Any, Any),0)
            end
            push!(max_points[c], (x, y))
        end

        min_points = Dict{ColorValue, Array{(Any, Any), 1}}()
        for (x, y, c) in zip(aes.x, aes.ymin, aes.color)
            if !haskey(min_points, c)
                min_points[c] = Array((Any, Any),0)
            end
            push!(min_points[c], (x, y))
        end

        for c in keys(max_points)
            sort!(max_points[c], by=first)
            sort!(min_points[c], by=first, rev=true)
        end

        ctx = compose!(
            context(),
            polygon([collect((Any, Any), chain(min_points[c], max_points[c]))
                     for c in keys(max_points)]),
            fill([theme.lowlight_color(c) for c in keys(max_points)]))
    end

    return compose!(
        ctx,
        svgclass("geometry"),
        stroke(nothing),
        linewidth(theme.line_width))
end

