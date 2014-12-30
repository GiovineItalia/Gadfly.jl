
using Gadfly

plot(layer(x=1:10, y=1:10, Geom.point, Theme(default_color=color("orange"))),
     layer(x=collect(1:10) .+ 0.1, y=collect(1:10) .+ 0.1, Geom.point,
           Theme(default_color=color("blue")), order=1))

