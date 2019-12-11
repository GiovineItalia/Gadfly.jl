struct BoxplotGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    suppress_outliers::Bool
    tag::Symbol
end

BoxplotGeometry(; method=:tukey, suppress_outliers=false, tag=empty_tag) =
    BoxplotGeometry(Gadfly.Stat.boxplot(method=method), suppress_outliers, tag)

"""
    Geom.boxplot[(; method=:tukey, suppress_outliers=false)]

Draw box plots of the `middle`, `lower_hinge`, `upper_hinge`, `lower_fence`,
`upper_fence`, and `outliers` aesthetics.  The categorical `x` aesthetic is
optional.  If `suppress_outliers` is true, don't draw points indicating
outliers.

Alternatively, if the `y` aesthetic is specified instead, the middle, hinges,
fences, and outliers aesthetics will be computed using [`Stat.boxplot`](@ref).

Boxplots will be automatically dodged by specifying a `color` aesthetic different to the `x` aesthetic.
"""
const boxplot = BoxplotGeometry

element_aesthetics(::BoxplotGeometry) = [:x, :color,
                                         :middle,
                                         :upper_fence, :lower_fence,
                                         :upper_hinge, :lower_hinge]  ### and :y, :outliers

default_statistic(geom::BoxplotGeometry) = geom.default_statistic

function render(geom::BoxplotGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.bar", aes,
                                     :lower_fence, :lower_hinge,
                                     :upper_hinge, :upper_fence,)
    Gadfly.assert_aesthetics_equal_length("Geom.bar", aes,
                                     :lower_fence, :lower_hinge, :middle,
                                     :upper_hinge, :upper_fence, :outliers)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGB{Float32}[theme.default_color])
    default_aes.x = Float64[0.5]
    aes = inherit(aes, default_aes)

    n = length(aes.lower_hinge)

    bw = 1w / n - theme.boxplot_spacing # boxplot width
    if length(aes.x) > 1
        xs_sorted = sort(aes.x)
        minspan = minimum([xj - xi for (xi, xj) in zip(xs_sorted[1:end-1],
                                                       xs_sorted[2:end])])
        bw = minspan*cx - theme.boxplot_spacing
    end

    fw = 2/3 * bw # fence width
    xs = Measure[x*cx for x in takestrict(cycle(aes.x), n)]
    cs = takestrict(cycle(aes.color), n)

    # We allow lower_hinge > upper_hinge, and lower_fence > upper_fence. So we
    # need to organize them for drawing here
    lower_hinge = similar(aes.lower_hinge)
    upper_hinge = similar(aes.upper_hinge)
    lower_fence = similar(aes.lower_fence)
    upper_fence = similar(aes.upper_fence)
    for (i, (lh, uh, lf, uf)) in enumerate(zip(aes.lower_hinge, aes.upper_hinge,
                                               aes.lower_fence, aes.upper_fence))
        if uh > lh
            lower_hinge[i] = aes.lower_hinge[i]
            upper_hinge[i] = aes.upper_hinge[i]
        else
            lower_hinge[i] = aes.upper_hinge[i]
            upper_hinge[i] = aes.lower_hinge[i]
        end

        if uf > lf
            lower_fence[i] = aes.lower_fence[i]
            upper_fence[i] = aes.upper_fence[i]
        else
            lower_fence[i] = aes.upper_fence[i]
            upper_fence[i] = aes.lower_fence[i]
        end
    end

    tbox, tlw, tuw, tlf, tuf, to, tm =
        subtags(geom.tag, :box, :lower_whisker, :upper_whisker,
                          :lower_fence, :upper_fence, :outliers, :middle)

    ctx = compose!(
        context(tag=geom.tag),
        fill(collect(cs)),
        stroke(collect(cs)),
        linewidth(theme.line_width),

        # Box
        rectangle(
            [x - bw/2 for x in xs],
            lower_hinge, [bw],
            [uh - lh for (lh, uh) in zip(lower_hinge, upper_hinge)], tbox),

        (
            context(),

             # Whiskers
            Compose.line([[(x, lh), (x, lf)]
                          for (x, lh, lf) in zip(xs, lower_hinge, lower_fence)], tlw),

            Compose.line([[(x, uh), (x, uf)]
                          for (x, uh, uf) in zip(xs, upper_hinge, upper_fence)], tuw),

            # Fences
            Compose.line([[(x - fw/2, lf), (x + fw/2, lf)]
                          for (x, lf) in zip(xs, lower_fence)], tlf),

            Compose.line([[(x - fw/2, uf), (x + fw/2, uf)]
                          for (x, uf) in zip(xs, upper_fence)], tuf),

            stroke(collect(cs))
        ),

        svgclass("geometry"))

    # Outliers
    if !geom.suppress_outliers && aes.outliers != nothing && !isempty(aes.outliers)
        xys = collect(Iterators.flatten(zip(cycle([x]), ys, cycle([c]))
                             for (x, ys, c) in zip(xs, aes.outliers, cs)))
        compose!(ctx, (context(),
            Shape.circle([x for (x, y, c) in xys], [y for (x, y, c) in xys], [theme.point_size], to), svgclass("marker"),
             stroke([theme.discrete_highlight_color(c) for (x, y, c) in xys]),
             fill([c for (x, y, c) in xys]) ))
    end

    # Middle
    if aes.middle != nothing
        compose!(ctx, (
           context(order=1),
           Compose.line([[(x - fw/2, mid), (x + fw/2, mid)]
                         for (x, mid) in zip(xs, aes.middle)], tm),
           linewidth(theme.middle_width),
           stroke([theme.middle_color(c) for c in cs])
        ))
    end

    return ctx
end
