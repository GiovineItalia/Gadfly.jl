using Gadfly

set_default_plot_size(6inch, 3inch)

plot(xgroup=["A", "A", "B", "B"],
     x=["X", "Y", "X", "Y"],
     y=[0.236033, 0.346517, 0.312707, 0.00790928],
     Geom.subplot_grid(Geom.bar))

plot(x=[0.488613, 0.210968, 0.951916],
     y=[0.999905, 0.251662, 0.986666],
     xgroup=["A", "A", "B"],
     ygroup=["X", "Y", "Y"],
     Geom.subplot_grid(Geom.bar))
