
using Gadfly, DataArrays, RDatasets

plot(dataset("datasets", "iris"), x=:SepalLength, y=:SepalWidth,
     color=:Species, Geom.point)

