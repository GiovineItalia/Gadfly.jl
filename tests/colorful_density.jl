
using Gadfly, RDatasets

plot(data("ggplot2", "diamonds"), x="price", color="cut", Geom.density)
