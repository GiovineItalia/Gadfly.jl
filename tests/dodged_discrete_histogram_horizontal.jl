
using RDatasets, DataArrays, Gadfly

plot(dataset("car", "SLID"), y=:Wages, color=:Language,
     Geom.histogram(position=:dodge, orientation=:horizontal))


