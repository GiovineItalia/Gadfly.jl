
using RDatasets, DataArrays, Gadfly

plot(dataset("car", "SLID"), x=:Wages, color=:Language,
     Geom.histogram(position=:dodge))


