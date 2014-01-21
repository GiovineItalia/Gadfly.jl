
using Gadfly, DataArrays, RDatasets

plot(data("ggplot2", "diamonds"),
     x="Price", color="Cut",
     Geom.histogram)

