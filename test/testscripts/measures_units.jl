using Gadfly

set_default_plot_size(6.6inch,3.3inch)

# Issue #1357

p1 = plot(xmin=[.25], xmax=[.75], Geom.band, color=[colorant"red"])
p2 = plot(xmin=[.25], xmax=[.75], Geom.band, color=[colorant"red"],
    layer(Geom.rect, xmin=[0], xmax=[1], ymin=[0], ymax=[1], color=[colorant"blue"]))


hstack(p1, p2)

