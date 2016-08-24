using Gadfly, RDatasets

# see issue #880
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut",
                   Geom.histogram(bincount=30, density=true))
