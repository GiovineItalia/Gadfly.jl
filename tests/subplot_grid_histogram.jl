
using RDatasets, DataArrays, Gadfly

plot(dataset("car", "Vocab"),
     xgroup="Year", x="Vocabulary",
     Geom.subplot_grid(Geom.histogram))

