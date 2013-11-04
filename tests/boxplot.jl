
using Gadfly
using RDatasets

 plot(data("lattice", "singer"), x="voice.part", y="height", Geom.boxplot)
