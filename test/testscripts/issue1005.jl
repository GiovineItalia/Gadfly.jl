using Gadfly, DataFrames

set_default_plot_size(6inch, 3inch)

points = DataFrame(
    index=[2,10,7,3,10,0,1,10,4,5,4,0,3,7,7,8,5,7,2,3,3,6,4,8,4,10,5,9,5,8],
    val=[6,10,4,2,4,9,1,1,7,4,8,2,2,2,7,9,1,3,7,10,2,3,10,7,8,9,2,6,6,10])
line = DataFrame(val=[4,3,10,6,10,2,3,2,4,7,4], index=collect(0:10))
pointLayer = layer(points, x="index", y="val", Geom.point,Theme(default_color="green"))
lineLayer = layer(line, x="index", y="val", Geom.line)
plot(pointLayer, lineLayer,
     Guide.manual_color_key("Legend", ["Points", "Line"], ["green", "deepskyblue"]))
