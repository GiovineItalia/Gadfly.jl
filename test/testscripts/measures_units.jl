using Gadfly

set_default_plot_size(8inch,3.3inch)

# Issue #1357

p1 = plot(xmin=[.25], xmax=[.75], Geom.band, color=[colorant"red"])
p2 = plot(xmin=[.25], xmax=[.75], Geom.band, color=[colorant"red"],
    layer(Geom.rect, xmin=[0], xmax=[1], ymin=[0], ymax=[1], color=[colorant"blue"]))
p3 = plot(x=[0,10], y=[0,1], Geom.blank,
    layer(xintercept=[1.2inch], Geom.vline(color="black")) )


hstack(p1, p2, p3)

