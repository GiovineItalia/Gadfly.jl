using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

plot(dataset("ggplot2", "diamonds"), x=:Price, Geom.histogram(bincount=30))
