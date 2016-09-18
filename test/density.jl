
using Gadfly, DataArrays, RDatasets, Distributions

plot(dataset("ggplot2", "diamonds"), x=:Price, Geom.density)

# manual densities
dist = MixtureModel(Normal, [(0.5, 0.2), (1, 0.1)])
xs = rand(dist, 10^5)
plot(layer(x=xs, Geom.density, Theme(default_color=colorant"orange")), 
layer(x=xs, Geom.density(bandwidth=0.003),
Theme(default_color=colorant"blue")),
layer(x=xs, Geom.density(bandwidth=0.25),
Theme(default_color=colorant"purple")),
Guide.manual_color_key("bandwidth", ["auto", "bw=0.003", "bw=0.25"],
["orange", "blue", "purple"]))
