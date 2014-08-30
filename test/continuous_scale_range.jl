
using Gadfly

n = 10
plot(x=rand(n), y=rand(n),
     Scale.x_continuous(minvalue=-10, maxvalue=10),
     Scale.y_continuous(minvalue=-10, maxvalue=10))

