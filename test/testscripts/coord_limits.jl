using Gadfly

set_default_plot_size(6inch, 6inch)

vstack(plot(sin, 0, 20, Coord.cartesian(xmin=2π, xmax=3π)),
       plot(sin, 0, 20, Coord.cartesian(ymin=-0.5, ymax=0.5)))
