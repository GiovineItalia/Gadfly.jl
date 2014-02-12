
using RDatasets, DataArrays, DataFrames, Gadfly

barley = data("lattice", "barley")
if isdefined(:setlevels!)
    setlevels!(barley[:Year], ["1931", "1932"])
else
    set_levels!(barley[:Year], ["1931", "1932"])
end

plot(barley,
     xgroup="Variety", ygroup="Site", x="Year", y="Yield",
     Geom.subplot_grid(Geom.line, Geom.point))


