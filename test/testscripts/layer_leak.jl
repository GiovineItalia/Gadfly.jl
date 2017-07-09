using Gadfly

set_default_plot_size(6inch, 3inch)

plot(layer(x=[1, 3], y=[1, 3], Geom.line),
     layer(x=[1, 2, 3], y=[1, 2, 3], color=[:a, :b, :c], Geom.point))
