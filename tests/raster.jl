
using Gadfly, DataArrays, RDatasets

plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP",
     Coord.cartesian(raster=true), Geom.rectbin)
