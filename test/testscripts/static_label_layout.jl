using Gadfly

set_default_plot_size(6inch, 16inch)

xs = [0.236033, 0.346517, 0.312707, 0.00790928, 0.488613, 0.210968, 0.951916, 0.999905, 0.251662, 0.986666]
ys = [0.555751, 0.437108, 0.424718, 0.773223, 0.28119, 0.209472, 0.251379, 0.0203749, 0.287702, 0.859512]
labels = String["mxhEmy", "9APlX1", "P17KC2", "2zNjTz", "g4mUef", "rcfI9s", "Bjd19K", "V1jjSR", "DEBHJk", "0J7d2j"]

l = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:left))
r = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:right))
a = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:above))
b = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:below))
c = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:centered))

vstack(l, r, a, b, c)
