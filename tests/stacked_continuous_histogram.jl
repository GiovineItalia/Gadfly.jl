
using Gadfly, RDatasets

plot(data("car", "SLID"), x="wages", color="language", Geom.histogram)

