using Gadfly

set_default_plot_size(6inch,3inch)

x, y = [1, 2, 3, 4], [3, 7, 5, 1]
xmin1, xmax1 = x.-0.1, x.+0.1
xmin2, xmax2 = x.-0.5, x.-0.3

lyr1 = layer(xmin=xmin1, xmax=xmax1, y=y, Geom.bar, color=[1])
lyr2 = layer(xmin=xmin2, xmax=xmax2, y=y, Geom.bar, color=[2])
cs = repeat([colorant"violet", colorant"hotpink"], outer=2)

p1 = plot(Theme(point_size=3pt), lyr1, lyr2,
    layer(x=x, y=y.+0.9, Geom.point, color=cs),
    Scale.color_discrete
)
p2 = plot(Theme(point_size=3pt), lyr1, lyr2,
    layer(x=x, y=y.+0.9, Geom.point, color=cs),
    Scale.color_continuous
)

hstack(p1, p2)