
using RDatasets
using Gadfly

plot(data("car", "SLID"), x="wages", color="language",
     Geom.histogram(:dodge))


