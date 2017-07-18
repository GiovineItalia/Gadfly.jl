using Gadfly

set_default_plot_size(6inch, 3inch)

plot(layer(x=1:10, y=1:10, Geom.point, Theme(default_color=colorant"orange")),
     layer(x=collect(1:10) .+ 0.1, y=collect(1:10) .+ 0.1, Geom.point,
           Theme(default_color=colorant"blue"), order=1))
