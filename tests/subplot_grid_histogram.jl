
using RDatasets
using Gadfly

plot(data("car", "Vocab"),
     x_group="year", x="vocabulary",
     Geom.subplot_grid(Geom.histogram))

