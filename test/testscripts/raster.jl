using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP",
     Coord.cartesian(raster=true), Geom.rectbin)
