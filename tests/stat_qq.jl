
using Gadfly
using Distributions

srand(1234)

x = rand(Normal(), 100)
y = rand(Normal(10), 100)

xd = Normal()
yd = Normal(10)

# two numeric vectors
plot(x=x, y=y, Stat.qq, Geom.point)

# one numeric and one Distribution
plot(x=x, y=yd, Stat.qq, Geom.point)
plot(x=xd, y=y, Stat.qq, Geom.point)

# Apply different scales to x and y
plot(x=x, y=exp(y), Stat.qq, Geom.point, Scale.y_log10)
plot(x=exp(x), y=y, Stat.qq, Geom.point, Scale.x_log10)

# Apply scales to Distributions
z = rand(Exponential(), 100)
plot(x=z, y=Exponential(), Stat.qq, Geom.point)
plot(x=log(z), y=Exponential(), Stat.qq, Geom.point)
plot(x=log(z), y=Exponential(), Stat.qq, Geom.point, Scale.y_log)
plot(x=z, y=Exponential(), Stat.qq, Geom.point, Scale.x_log, Scale.y_log)

# by analogy with Stat.func, computed (.y) aes should be scaled:
#plot(xmin=[1], xmax=[15], y=[exp], Stat.func, Geom.line)
# (y value is log(exp(x), or y=x)
#plot(xmin=[1], xmax=[15], y=[exp], Stat.func, Geom.line, Scale.y_log)

# Binding other aesthetics
plot(x=x, y=Normal(), color=rand(length(x)), Stat.qq, Geom.point)
