
using RDatasets, DataArrays, DataFrames, Gadfly

barley = data("lattice", "barley")
setlevels!(barley["Year"], ["1931", "1932"])

plot(barley,
     xgroup="Variety", ygroup="Site", x="Year", y="Yield",
     Geom.subplot_grid(Geom.line, Geom.point))


