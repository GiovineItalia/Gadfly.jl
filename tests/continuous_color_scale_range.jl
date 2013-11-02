
using Gadfly

n = 10
plot(x=rand(n), y=rand(n), color=rand(n),
     Scale.continuous_color(minvalue=-10, maxvalue=10))


