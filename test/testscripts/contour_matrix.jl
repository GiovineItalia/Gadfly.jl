using Gadfly, Compat

set_default_plot_size(6inch, 3inch)

f(x,y) = x*exp(-(x-(round(Int, x)))^2-y^2)
M = Array{Float64}(200, 200)
for (i, x) in enumerate(linspace(-8., 8., 200)), (j, y) in enumerate(linspace(-2., 2., 200))
    M[i, j] = f(x, y)
end

plot(z=M, Geom.contour, xmin=[-8.], xmax=[8], ymin=[-2.], ymax=[2])
