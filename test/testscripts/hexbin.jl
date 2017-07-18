using Gadfly, Distributions

set_default_plot_size(6inch, 3inch)

vals = rand(MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0]), 10000)
plot(x=vals[1,:], y=vals[2,:], Geom.hexbin)
