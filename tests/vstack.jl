
using Gadfly, DataArrays, RDatasets, DataFrames

iris = data("datasets", "iris")

vstack(
    Plot[plot(subset(iris, :(Species .== $(species))),
         x="SepalLength", y="SepalWidth", Geom.point)
         for species in ["setosa", "versicolor", "virginica"]])

