using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
     Theme(grid_line_style=:solid),
     Geom.point)
