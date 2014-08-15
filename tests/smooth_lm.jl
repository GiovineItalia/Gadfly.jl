
using Gadfly

x = rand(40)
y = 4.*x .+ 2 .+randn(40)
plot(x=x,y=y, Geom.point, Geom.smooth(method=:lm))


