using Gadfly, Compat

set_default_plot_size(6inch, 3inch)

f(x,y) = x*exp(-(x-(round(Int, x)))^2-y^2)
M = Array{Float64}(undef, 200, 200)
for (i, x) in enumerate(range(-8., stop=8., length=200)), (j, y) in enumerate(range(-2., stop=2., length=200))
    M[i, j] = f(x, y)
end

plot(z=M, Geom.contour, xmin=[-8.], xmax=[8], ymin=[-2.], ymax=[2])
