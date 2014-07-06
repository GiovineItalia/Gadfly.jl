
immutable BoxplotGeometry <: Gadfly.GeometryElement
end


const boxplot = BoxplotGeometry

element_aesthetics(::BoxplotGeometry) = [:x, :y, :color,
                                         :middle,
                                         :upper_fence, :lower_fence,
                                         :upper_hinge, :lower_hinge]

default_statistic(::BoxplotGeometry) = Gadfly.Stat.boxplot()

function render(geom::BoxplotGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    Gadfly.assert_aesthetics_defined("Geom.bar", aes,
                                     :lower_fence, :lower_hinge,
                                     :upper_hinge, :upper_fence,)
    Gadfly.assert_aesthetics_equal_length("Geom.bar", aes,
                                     :lower_fence, :lower_hinge, :middle,
                                     :upper_hinge, :upper_fence, :outliers)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    default_aes.x = Float64[0.5]
    aes = inherit(aes, default_aes)

    n = length(aes.lower_hinge)
    bw = 1w / n - theme.boxplot_spacing # boxplot width
    fw = 2/3 * bw # fence width
    xs = [Measure(cx=x) for x in takestrict(cycle(aes.x), n)]
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

    ctx = compose!(
        context(),
        fill(collect(cs)),
        stroke(collect(cs)),
        linewidth(theme.line_width),
        {
            context(),

            # Box
            rectangle(
                [x - bw/2 for x in xs],
                lower_hinge, [bw],
                [uh - lh for (lh, uh) in zip(lower_hinge, upper_hinge)]),

            {
                context(),

                 # Whiskers
                Compose.line([[(x, lh), (x, lf)]
                              for (x, lh, lf) in zip(xs, lower_hinge, lower_fence)]),

                Compose.line([[(x, uh), (x, uf)]
                              for (x, uh, uf) in zip(xs, upper_hinge, upper_fence)]),

                # Fences
                Compose.line([[(x - fw/2, lf), (x + fw/2, lf)]
                              for (x, lf) in zip(xs, lower_fence)]),

                Compose.line([[(x - fw/2, uf), (x + fw/2, uf)]
                              for (x, uf) in zip(xs, upper_fence)]),

                stroke(collect(cs))
            },

        },
        svgclass("geometry"))

    # Outliers
    if aes.outliers != nothing && !isempty(aes.outliers)
        xys = collect(chain([zip(cycle([x]), ys, cycle([c]))
                             for (x, ys, c) in zip(xs, aes.outliers, cs)]...))
        compose!(ctx,
            (context(),
             circle([x for (x, y, c) in xys],
                    [y for (x, y, c) in xys],
                    [theme.default_point_size]),
             stroke([theme.discrete_highlight_color(c) for (x, y, c) in xys]),
             fill([c for (x, y, c) in xys])))
    end

    # Middle
    if aes.middle != nothing
        compose!(ctx, {
           context(order=1),
           Compose.line([[(x - fw/2, mid), (x + fw/2, mid)]
                         for (x, mid) in zip(xs, aes.middle)]),
           linewidth(theme.middle_width),
           stroke([theme.middle_color(c) for c in cs])
        })
    end

    return ctx
end


