using Gadfly

set_default_plot_size(6inch, 3inch)

plot(layer(y=20*rand(20), Geom.bar), layer(x=20*rand(20), Geom.line))
