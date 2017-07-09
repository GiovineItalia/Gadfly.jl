using Gadfly

set_default_plot_size(6inch, 6inch)

plot(x=rand(100), y=rand(100), color=rand(1:8, 100),
     Geom.point)
