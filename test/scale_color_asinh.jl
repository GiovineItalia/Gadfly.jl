using Gadfly

n = 10
plot(x=rand(n), y=rand(n), color=sinh(rand(n)), Scale.color_asinh)
