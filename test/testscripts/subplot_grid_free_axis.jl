using RDatasets, DataArrays, DataFrames, Gadfly

set_default_plot_size(10inch, 10inch)

barley = dataset("lattice", "barley")
if isdefined(:setlevels!)
    setlevels!(barley[:Year], ["1931", "1932"])
else
    set_levels!(barley[:Year], ["1931", "1932"])
end

idx = [startswith(x,"No.") for x in barley[:Variety]]
plot(barley[idx,:],
     xgroup="Variety", ygroup="Site", x="Year", y="Yield",
     Geom.subplot_grid(Geom.line, Geom.point,
                       free_x_axis=true, free_y_axis=true))
