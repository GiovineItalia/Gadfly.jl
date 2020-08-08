using Gadfly, RDatasets, Distributions

set_default_plot_size(6inch, 3inch)

plot(dataset("ggplot2", "diamonds"), x=:Price, Geom.density)

# manual densities
dist = MixtureModel(Normal, [(0.5, 0.2), (1, 0.1)])
xs = rand(dist, 10^5)
plot(layer(x=xs, Geom.density, color=["auto"]),
    layer(x=xs, Geom.density(bandwidth=0.0003), color=["bw=0.0003"]),
    layer(x=xs, Geom.density(bandwidth=0.25), color=["bw=0.25"]),
    Scale.color_discrete_manual("orange", "green", "purple"),
    Guide.colorkey(title="bandwidth"))
    