using Gadfly

set_default_plot_size(6inch, 3inch)

t = [0:0.2:2pi;]
plot(x=cos.(t), y=sin.(t), Geom.line(preserve_order=true))
plot(x=cos.(t), y=sin.(t), Geom.path)
