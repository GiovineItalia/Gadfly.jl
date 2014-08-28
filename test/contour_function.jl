
using Gadfly

plot((x,y) -> x*exp(-(x-int(x))^2-y^2), -8., 8, -2., 2)


