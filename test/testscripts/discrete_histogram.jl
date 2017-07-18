using Gadfly, Distributions

set_default_plot_size(6inch, 3inch)

plot(x=rand(Poisson(20), 1000), Scale.x_discrete, Geom.histogram)
