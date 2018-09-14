using Gadfly

set_default_plot_size(6inch, 3inch)

n = 10
plot(x=fill(1, n),
     y=[0.905597, 0.941418, 0.545107, 0.0393329, 0.355558, 0.0472913, 0.360985, 0.438887, 0.273428, 0.984925],
     Geom.bar)
