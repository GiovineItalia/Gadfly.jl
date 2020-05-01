using Gadfly

set_default_plot_size(6.6inch, 6.6inch)

# contour_color_none, contour_function, contour_layers, contour_matrix
xs = 1:10.
ys = xs
zs = Float64[x^2*log(y) for x in xs, y in ys]

f(x,y) = x*exp(-(x-(round(Int, x)))^2-y^2)
M = Array{Float64}(undef, 200, 200)
for (i, x) in enumerate(range(-8., stop=8., length=200)), (j, y) in enumerate(range(-2., stop=2., length=200))
    M[i, j] = f(x, y)
end

p1 = plot(x=xs, y=ys, z=zs, Geom.contour, Scale.color_none)
p2 = plot((x,y) -> x*exp(-(x-(round(Int, x)))^2-y^2), -8., 8, -2., 2)
p3 = plot(layer((x,y) -> x*exp(-(x-(round(Int, x)))^2-y^2), -8., 8, -2., 2),
     layer((x, y) -> sqrt(hypot(x, y)), -2, 2, -1, 1),
     layer(x=[3], y=[1.5], Geom.point))
p4 = plot(z=M, Geom.contour, xmin=[-8.], xmax=[8], ymin=[-2.], ymax=[2])


gridstack([p1 p2; p3 p4])
