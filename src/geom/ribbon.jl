
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
                aes::Gadfly.Aesthetics)
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

        form = compose(polygon(chain(min_points, max_points)...),
                       fill(theme.lowlight_color(aes.color[1])),
                       svgclass("geometry"))
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

        forms = Array(Any, length(max_points))
        for (i, c) in enumerate(keys(max_points))
            c_max_points = max_points[c]
            c_min_points = min_points[c]
            sort!(c_max_points, by=first)
            sort!(c_min_points, by=first, rev=true)

            forms[i] =
                compose(polygon(chain(c_min_points, c_max_points)...),
                        fill(theme.lowlight_color(c)),
                        opacity(theme.lowlight_opacity),
                        svgclass(@sprintf("geometry color_%s",
                                          escape_id(aes.color_label([c])[1]))))
        end
        form = combine(forms...)
    end

    compose(form, stroke(nothing), linewidth(theme.line_width))
end

