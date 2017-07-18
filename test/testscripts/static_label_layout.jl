using Gadfly

set_default_plot_size(6inch, 16inch)

n = 10
xs, ys, labels = rand(n), rand(n), [randstring(6) for _ in 1:n]

l = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:left))
r = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:right))
a = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:above))
b = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:below))
c = plot(x=xs, y=ys, label=labels, Geom.point, Geom.label(position=:centered))

vstack(l, r, a, b, c)
