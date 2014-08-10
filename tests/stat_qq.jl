
using Gadfly
using Distributions

x = rand(Normal(), 100)
y = rand(Normal(10), 100)

xd = Normal()
yd = Normal(10)

# two numeric vectors
plot(x=x, y=y, Stat.qq, Geom.point)

# one numeric and one Distribution
plot(x=x, y=yd, Stat.qq, Geom.point)
plot(x=xd, y=y, Stat.qq, Geom.point)

