
using Gadfly, DataArrays, RDatasets

plot(dataset("car", "SLID"), x="Wages", color="Language", Stat.histogram, Geom.line)


