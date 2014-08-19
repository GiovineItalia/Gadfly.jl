using Gadfly

plot(layer(Geom.line, x=1:10, y=1:10, Theme(default_color=color("red"))),
     layer(Geom.point, Geom.label, x=[5], y=[5], label=["5"]))
