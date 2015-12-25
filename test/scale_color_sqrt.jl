using Gadfly

n = 10
plot(x=rand(n), y=rand(n), color=sqrt(rand(n)), Scale.color_sqrt)
