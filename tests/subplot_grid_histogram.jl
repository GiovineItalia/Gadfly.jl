
using RDatasets, DataArrays, Gadfly

plot(data("car", "Vocab"),
     xgroup="Year", x="Vocabulary",
     Geom.subplot_grid(Geom.histogram))

