using Gadfly

set_default_plot_size(6inch, 3inch)

n = 10
plot(x=fill(1, n), y=rand(n), Geom.bar)
