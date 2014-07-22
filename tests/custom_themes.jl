
using Gadfly, DataArrays, RDatasets

custom_theme = Theme(panel_fill=color("black"),
                     default_color=color("pink"))

plot(dataset("datasets", "iris"), x=:SepalLength, y=:SepalWidth, Geom.point,
     custom_theme)
