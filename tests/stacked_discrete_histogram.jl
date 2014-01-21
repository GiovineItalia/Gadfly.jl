
using RDatasets, DataArrays, Gadfly

plot(data("car", "SLID"), x="Wages", color="Language",
     Geom.histogram(position=:stack))


