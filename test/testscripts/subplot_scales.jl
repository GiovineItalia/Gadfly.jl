using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=rand(20), y=rand(20),
     color=vcat(fill("A", 5), fill("B", 5), fill("C", 5), fill("D", 5)),
     ygroup=vcat(fill("U", 10), fill("V", 10)),
     Geom.subplot_grid(Scale.color_discrete, Geom.line))
