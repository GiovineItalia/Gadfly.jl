
using RDatasets, DataArrays, Gadfly

plot(dataset("car", "SLID"), color="Language", y="Wages",
     Geom.histogram(position=:stack, orientation=:horizontal))


