using Gadfly

set_default_plot_size(6inch, 3inch)

plot(sin, 0, 25, Coord.cartesian(aspect_ratio=1.0))
