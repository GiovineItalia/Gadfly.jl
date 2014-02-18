
using Gadfly, DataArrays, RDatasets

plot(dataset("car", "SLID"), x="Wages", color="Language", Geom.histogram)

