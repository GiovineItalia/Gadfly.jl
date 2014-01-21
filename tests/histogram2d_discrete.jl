
using RDatasets, DataArrays, Gadfly

plot(data("car", "Womenlf"), x="HIncome", y="Region", Geom.histogram2d)

