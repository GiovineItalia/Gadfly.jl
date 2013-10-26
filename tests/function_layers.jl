
using Gadfly
using RDatasets

plot(data("datasets", "iris"),
     layer(x="Sepal.Length", y="Sepal.Width", Geom.point),
     layer([sin, cos], 0, 25))
