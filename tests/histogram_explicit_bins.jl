
using Gadfly, DataArrays, RDatasets

plot(dataset("ggplot2", "diamonds"), x=:Price, Geom.histogram(bincount=30))



