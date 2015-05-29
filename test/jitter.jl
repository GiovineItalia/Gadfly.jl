
using Gadfly, DataArrays, RDatasets

plot(dataset("datasets", "iris"), x=:SepalLength, y=:SepalWidth, color=:Species,
     Stat.x_jitter, Stat.y_jitter, Geom.point)


