
using RDatasets
using Gadfly

plot(data("car", "Vocab"),
     xgroup="year", x="vocabulary",
     Geom.subplot_grid(Geom.histogram))

