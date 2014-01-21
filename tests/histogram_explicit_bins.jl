
using Gadfly, DataArrays, RDatasets

plot(data("ggplot2", "diamonds"), x="Price", Geom.histogram(bincount=30))



