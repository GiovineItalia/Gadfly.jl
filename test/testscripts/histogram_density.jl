using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

# see issue #880
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut",
                   Geom.histogram(bincount=30, density=true))
