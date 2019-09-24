using Gadfly, RDatasets, DataFrames

set_default_plot_size(6inch, 3inch)

iris = dataset("datasets", "iris")

plots = Plot[]
for species in ["setosa", "versicolor", "virginica"]
    iris_subset = iris[iris.Species .== species, :]
    push!(plots, plot(iris_subset, x=:SepalLength, y=:SepalWidth, Geom.point))
end
hstack(plots)
