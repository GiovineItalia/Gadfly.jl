
using Gadfly, Distributions

plot(x=rand(Poisson(20), 1000), Scale.x_discrete, Geom.histogram)


