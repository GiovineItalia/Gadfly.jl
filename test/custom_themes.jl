
using Gadfly, DataArrays, RDatasets

custom_theme = Theme(panel_fill=colorant"black",
                     default_color=colorant"pink",
                     background_color=colorant"red")

plot(dataset("datasets", "iris"), x=:SepalLength, y=:SepalWidth, Geom.point,
     custom_theme)

