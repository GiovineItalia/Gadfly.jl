
using Gadfly

#plot(layer(x=[0, 1, 1, 0], y=[0, 1, 0, 1], ygroup=["A", "A", "B", "B"],
           #Geom.subplot_grid(Geom.line), Theme(default_color=color("red"))),
     #layer(x=[0.5, 1.5, 1.5, 0.5], y=[0, 1, 0, 1], ygroup=["A", "A", "B", "B"],
           #Geom.subplot_grid(Geom.line), Theme(default_color=color("blue"))))


plot(ygroup=["A", "A", "B", "B"],
     Geom.subplot_grid(
        layer(x=[0, 1, 1, 0], y=[0, 1, 0, 1],
              Geom.line, Theme(default_color=color("red"))),
        layer(x=[0.5, 1.5, 1.5, 0.5], y=[0, 1, 0, 1],
              Geom.line, Theme(default_color=color("blue")))))


