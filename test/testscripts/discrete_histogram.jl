using Gadfly, Distributions

set_default_plot_size(7inch, 3inch)

x = sort!(rand(Poisson(20), 1000))
p1 = plot(x=x, Scale.x_discrete, Geom.histogram)
p2 = plot(x=x, Scale.x_discrete, Geom.histogram(density=true))
hstack(p1, p2)
