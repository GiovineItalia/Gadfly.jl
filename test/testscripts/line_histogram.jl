using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

plot(dataset("car", "SLID"), x="Wages", color="Language", Stat.histogram, Geom.line)
