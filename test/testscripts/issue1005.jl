using Gadfly, DataFrames

set_default_plot_size(6inch, 3inch)

points = DataFrame(index=rand(0:10,30), val=rand(1:10,30))
line = DataFrame(val=rand(1:10,11), index = collect(0:10))
pointLayer = layer(points, x="index", y="val", Geom.point,Theme(default_color="green"))
lineLayer = layer(line, x="index", y="val", Geom.line)
plot(pointLayer, lineLayer, Guide.manual_color_key("Legend", ["Points", "Line"], ["green", "deepskyblue"]))
