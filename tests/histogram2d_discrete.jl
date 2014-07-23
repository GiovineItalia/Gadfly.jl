
using RDatasets, DataArrays, Gadfly

plot(dataset("car", "Womenlf"), x=:HIncome, y=:Region, Geom.histogram2d)

