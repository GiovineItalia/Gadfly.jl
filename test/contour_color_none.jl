
using Gadfly

xs = 1:10.
ys = xs
zs = Float64[x^2*log(y) for x in xs, y in ys]
plot(x=xs, y=ys, z=zs, Geom.contour, Scale.color_none)
