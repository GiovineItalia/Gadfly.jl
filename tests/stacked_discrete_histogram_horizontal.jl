
using RDatasets, DataArrays, Gadfly

plot(data("car", "SLID"), color="Language", y="Wages",
     Geom.histogram(position=:stack, orientation=:horizontal))


