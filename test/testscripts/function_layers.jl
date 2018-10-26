using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

plot(dataset("datasets", "iris"),
     layer(x=:SepalLength, y=:SepalWidth, Geom.point),
     layer([sin, cos], 0, 25))
