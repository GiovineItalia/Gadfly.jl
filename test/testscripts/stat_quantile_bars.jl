using Gadfly, RDatasets, Distributions

set_default_plot_size(6inch, 3inch)

plot(dataset("ggplot2", "diamonds"), x=:Price, Stat.quantile_bars, Geom.segment)

dist = MixtureModel(Normal, [(0.5, 0.2), (1, 0.1)])
xs = rand(dist, 10^5)
p = plot(
    layer(x=xs, Stat.quantile_bars(quantiles=[0.1, 0.9]), Geom.segment, color=["auto"]),
    layer(x=xs, Geom.density, color=["auto"]),
    layer(x=xs, Stat.quantile_bars(bandwidth=0.0003), Geom.segment, color=["bw=0.0003"]),
    layer(x=xs, Geom.density(bandwidth=0.0003), color=["bw=0.0003"]),
    Scale.color_discrete_manual("orange", "green"),
    Guide.colorkey(title="bandwidth")
);
