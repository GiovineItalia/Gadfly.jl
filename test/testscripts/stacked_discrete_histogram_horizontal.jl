using RDatasets, Gadfly

set_default_plot_size(6inch, 3inch)

plot(dataset("car", "SLID"), color="Language", y="Wages",
     Geom.histogram(position=:stack, orientation=:horizontal))
