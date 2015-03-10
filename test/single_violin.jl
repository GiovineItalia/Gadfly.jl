
using Gadfly, Distributions

plot(y=rand(Normal(), 100), Geom.violin)
