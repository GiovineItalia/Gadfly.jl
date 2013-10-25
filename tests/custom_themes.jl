
using Gadfly
using RDatasets

custom_theme = Theme(panel_fill=color("black"),
                     default_color=color("pink"))

plot(data("datasets", "iris"), x="Sepal.Length", y="Sepal.Width", Geom.point,
     custom_theme)
