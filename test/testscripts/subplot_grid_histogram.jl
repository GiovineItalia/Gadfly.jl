using RDatasets, Gadfly

set_default_plot_size(10inch, 3inch)

plot(dataset("car", "Vocab"),
     xgroup="Year", x="Vocabulary",
     Geom.subplot_grid(Geom.histogram))
