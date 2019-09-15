using RDatasets, DataFrames, Gadfly

set_default_plot_size(10inch, 10inch)

barley = dataset("lattice", "barley")
levels!(barley.Year, ["1931", "1932"])

idx = [startswith(x,"No.") for x in barley.Variety]
plot(barley[idx,:],
     xgroup="Variety", ygroup="Site", x="Year", y="Yield",
     Geom.subplot_grid(Geom.line, Geom.point,
                       free_x_axis=true, free_y_axis=true))
