using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

plot(dataset("car", "UN"), x=:GDP, y=:InfantMortality,
     Geom.histogram2d(xbincount=20, ybincount=20),
     Scale.x_log10, Scale.y_log10)
