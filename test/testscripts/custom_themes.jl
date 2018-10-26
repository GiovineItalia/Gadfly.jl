using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

custom_theme = Theme(panel_fill=colorant"black",
                     default_color=colorant"pink",
                     background_color=colorant"red")

plot(dataset("datasets", "iris"), x=:SepalLength, y=:SepalWidth, Geom.point,
     custom_theme)
