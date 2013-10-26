
using Gadfly, RDatasets

 plot(data("ggplot2", "diamonds"), x="price", Geom.density)

