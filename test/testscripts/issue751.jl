using Gadfly

set_default_plot_size(6.6inch, 3.3inch)

p1 = plot(x=[], y=[], Geom.point)
p2 = plot(x=[], y=[], Geom.line,
    Guide.xticks(ticks=[0,10]), Guide.yticks(ticks=[0,10])
)

hstack(p1,p2)


