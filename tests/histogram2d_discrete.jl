
using RDatasets, Gadfly

plot(data("car", "Womenlf"), x="hincome", y="region", Geom.histogram2d)

