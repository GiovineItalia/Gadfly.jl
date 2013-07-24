
using Gadfly
using RDatasets
using DataFrames

iris = data("datasets", "iris")

vstack(
    [plot(subset(iris, :(Species .== $(species))),
         x="Sepal.Length", y="Sepal.Width", Geom.point)
     for species in ["setosa", "versicolor", "virginica"]])

