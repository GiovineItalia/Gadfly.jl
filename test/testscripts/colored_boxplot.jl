using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

mpg = dataset("ggplot2","mpg")
plot(mpg, x=:Class, y=:Hwy, Geom.boxplot, color=:Class)