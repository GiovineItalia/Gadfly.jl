using Gadfly

set_default_plot_size(6inch, 3inch)

x, y, size = rand(10), rand(10), rand(["foo","bar","pooh"], 10)
levels = sort(unique(size))
p1 = plot(x=x, y=y, size=size, Geom.point, Scale.size_discrete(levels=levels))
p2 = plot(x=x, y=y, size=size, Geom.point, Scale.size_discrete2(levels=levels),
    Theme(key_swatch_shape=Shape.circle))

hstack(p1, p2)
