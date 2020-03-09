using Gadfly

set_default_plot_size(6inch, 3inch)

x = [1, 2, 3, 4, 5]
y = [1.0, 2.0, NaN, 4.0, 5.0]
plot(x=x, y=y, ymin=y.-0.5, ymax=y.+0.5, Geom.line, Geom.point, Geom.ribbon)
