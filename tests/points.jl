
using Gadfly
using RDatasets

plot(data("datasets", "iris"), x="Sepal.Length", y="Sepal.Width", Geom.point)

