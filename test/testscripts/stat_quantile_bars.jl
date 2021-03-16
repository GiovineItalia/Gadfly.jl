using Gadfly, RDatasets, Distributions

set_default_plot_size(6inch, 3inch)

xs = dataset("datasets", "faithful").Waiting

quantiles = [0.1, 0.9]
p1 = plot(x=xs, Geom.density, Guide.title("quantiles=$quantiles"),
        layer(x=xs, Stat.quantile_bars(quantiles=quantiles), Geom.segment))

bandwidth = 0.6
p2 = plot(x=xs, Stat.density(bandwidth=bandwidth), Geom.line, Guide.title("bandwidth=$bandwidth"),
    layer(x=xs, Stat.quantile_bars(bandwidth=bandwidth), Geom.segment))

p = hstack(p1, p2)
