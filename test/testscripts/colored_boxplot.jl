using Compose, Gadfly, RDatasets

set_default_plot_size(21cm, 16cm)

mpg = dataset("ggplot2","mpg")
p1 = plot(mpg, x=:Class, y=:Hwy, color=:Class, Geom.boxplot, Theme(boxplot_spacing=0.3cx) )

p2 = plot(mpg, x=:Class, y=:Hwy, color=:Drv, Geom.boxplot,
    Guide.colorkey(labels=["front", "4-wheel\t\t","rear"]),
    Theme(boxplot_spacing=0.1cx) )

vstack(p1, p2)