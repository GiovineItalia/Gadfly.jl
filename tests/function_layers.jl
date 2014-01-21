
using Gadfly, DataArrays, RDatasets

plot(data("datasets", "iris"),
     layer(x="SepalLength", y="SepalWidth", Geom.point),
     layer([sin, cos], 0, 25))
