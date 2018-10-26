struct RibbonGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    tag::Symbol
end
RibbonGeometry(default_statistic=Gadfly.Stat.identity(); tag=empty_tag) =
        RibbonGeometry(default_statistic, tag)

"""
    Geom.ribbon

Draw a ribbon at the positions in `x` bounded above and below by `ymax` and
`ymin`, respectively.  Optionally draw multiple ribbons by grouping with `color`.
"""
const ribbon = RibbonGeometry

default_statistic(geom::RibbonGeometry) = geom.default_statistic

element_aesthetics(::RibbonGeometry) = [:x, :ymin, :ymax, :color]

function render(geom::RibbonGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.ribbon", aes, :x, :ymin, :ymax)
    Gadfly.assert_aesthetics_equal_length("Geom.ribbon", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGB{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    aes_x, aes_ymin, aes_ymax = concretize(aes.x, aes.ymin, aes.ymax)

    if length(aes.color) == 1 &&
        !(isa(aes.color, IndirectArray) && length(filter(!ismissing, aes.color.values)) > 1)
        max_points = collect(zip(aes_x, aes_ymax))
        sort!(max_points, by=first)

        min_points = collect(zip(aes_x, aes_ymin))
        sort!(min_points, by=first, rev=true)

        ctx = compose!(
            context(),
            Compose.polygon([collect(Iterators.flatten((min_points, max_points)))]),
            fill(theme.lowlight_color(aes.color[1])))
    else
        XT, YT = eltype(aes_x), promote_type(eltype(aes_ymin), eltype(aes_ymax))
        max_points = Dict{RGB{Float32}, Vector{(Tuple{XT, YT})}}()
        for (x, y, c) in zip(aes_x, aes_ymax, aes.color)
            if !haskey(max_points, c)
                max_points[c] = Array{Tuple{XT, YT}}(undef, 0)
            end
            push!(max_points[c], (x, y))
        end

        min_points = Dict{RGB{Float32}, Vector{(Tuple{XT, YT})}}()
        for (x, y, c) in zip(aes.x, aes.ymin, aes.color)
            if !haskey(min_points, c)
                min_points[c] = Array{Tuple{XT, YT}}(undef, 0)
            end
            push!(min_points[c], (x, y))
        end

        for c in keys(max_points)
            sort!(max_points[c], by=first)
            sort!(min_points[c], by=first, rev=true)
        end

        ctx = compose!(
            context(),
            Compose.polygon([collect((Tuple{XT, YT}), Iterators.flatten((min_points[c], max_points[c])))
                     for c in keys(max_points)], geom.tag),
            fill([theme.lowlight_color(c) for c in keys(max_points)]))
    end

    return compose!(
        ctx,
        svgclass("geometry"),
        stroke(nothing),
        linewidth(theme.line_width))
end
