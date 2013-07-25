
using Gadfly
using RDatasets

plot(data("ggplot2", "diamonds"),
     x="price", color="cut",
     Geom.bar)

