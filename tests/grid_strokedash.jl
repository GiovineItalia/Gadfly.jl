using Gadfly, DataArrays, RDatasets

plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
     Theme(grid_strokedash=[]),
     Geom.point)

