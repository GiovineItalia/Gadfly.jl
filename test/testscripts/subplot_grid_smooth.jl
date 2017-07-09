using Gadfly

set_default_plot_size(6inch, 8inch)

plot(x=rand(40), y=rand(40),
     xgroup=vcat(fill("A", 20), fill("B", 20)),
     ygroup=vcat(fill("X", 10), fill("Y", 10), fill("X", 10), fill("Y", 10)),
     Geom.subplot_grid(Geom.smooth))
