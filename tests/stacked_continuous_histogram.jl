
using Gadfly, DataArrays, RDatasets

plot(data("car", "SLID"), x="Wages", color="Language", Geom.histogram)

