
immutable BoxplotGeometry <: Gadfly.GeometryElement
end


const boxplot = BoxplotGeometry

element_aesthetics(::BoxplotGeometry) = [:x, :y, :color,
                                         :middle,
                                         :upper_fence, :lower_fence,
                                         :upper_hinge, :lower_hinge]

default_statistic(::BoxplotGeometry) = Gadfly.Stat.boxplot()

function render(geom::BoxplotGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
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

    bw = 1.0cx - theme.boxplot_spacing
    xs = take(cycle(aes.x), length(aes.middle))
    cs = take(cycle(aes.color), length(aes.middle))

    ctx = compose!(
        context(),
        fill(collect(cs)),
        stroke([theme.discrete_highlight_color(c) for c in cs]),
        linewidth(theme.line_width),
        {
            context(),

            # Box
            rectangle(
                [x*cx - bw/2 for x in xs],
                aes.lower_hinge, [bw],
                [uh - lh for (lh, uh) in zip(aes.lower_hinge, aes.upper_hinge)]),

            {
                context(),

                 # Whiskers
                Compose.line([[(x, lh), (x, lf)]
                              for (x, lh, lf) in zip(xs, aes.lower_hinge, aes.lower_fence)]),

                Compose.line([[(x, uh), (x, uf)]
                              for (x, uh, uf) in zip(xs, aes.upper_hinge, aes.upper_fence)]),

                # Fences
                Compose.line([[(x - 1/6, lf), (x + 1/6, lf)]
                              for (x, lf) in zip(xs, aes.lower_fence)]),

                Compose.line([[(x - 1/6, uf), (x + 1/6, uf)]
                              for (x, uf) in zip(xs, aes.upper_fence)]),

                stroke(collect(cs))
            },

        },
        svgclass("geometry"))

    # Outliers
    if aes.outliers != nothing && !isempty(aes.outliers)
        xys = collect(chain([zip(cycle(x), ys, cycle([c]))
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
           Compose.line([[(x - 1/6, mid), (x + 1/6, mid)]
                         for (x, mid) in zip(xs, aes.middle)]),
           linewidth(theme.middle_width),
           stroke([theme.middle_color(c) for c in cs])
        })
    end

    return ctx
end


