using Gadfly

set_default_plot_size(6inch, 3inch)

x, y, size = rand(10), rand(10), rand(["foo","bar","pooh"], 10)
p1 = plot(x=x, y=y, size=size, Geom.point)
p2 = plot(x=x, y=y, size=size, Geom.point, Scale.size_discrete2)

hstack(p1, p2)
