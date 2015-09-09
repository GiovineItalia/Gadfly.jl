
using Gadfly, Compat

f(x,y) = x*exp(-(x-(@compat round(Int, x)))^2-y^2)
M = Array(Float64, (200, 200))
for (i, x) in enumerate(linspace(-8., 8., 200)), (j, y) in enumerate(linspace(-2., 2., 200))
    M[i, j] = f(x, y)
end

plot(z=M, Geom.contour, xmin=[-8.], xmax=[8], ymin=[-2.], ymax=[2])

xs = 1:10.
ys = xs
zs = Float64[x^2*log(y) for x in xs, y in ys]
plot(x=xs, y=ys, z=zs, Geom.contour, Scale.color_none)
