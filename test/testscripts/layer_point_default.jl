using Gadfly

set_default_plot_size(6inch, 3inch)

# these should both use Geom.point by default, see #1062
plot(x=[1,2,3], y=[4,5,6])
plot(layer(x=[1,2,3], y=[4,5,6]))
