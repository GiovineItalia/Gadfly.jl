using DataFrames, Gadfly
set_default_plot_size(6.6inch, 3.3inch)

expand_grid(xv, yv, n::Int) = vcat([[x y z] for x in xv, y in yv, z in 1:n]...)

a = expand_grid(6.0:10, 1.0:4, 3)

D= DataFrame(x= a[:,1], y=a[:,2], z=a[:,3].*a[:,1].*a[:,2], g = string.(floor.(Int, a[:,3])) )
coord = Coord.cartesian(xmin=6, xmax=10, ymin=1, ymax=4)

plot(D, xgroup=:g, x=:x, y=:y, color=:z,
    Geom.subplot_grid(coord, layer(z=:z, Geom.contour(levels=7))),
    Scale.color_continuous(minvalue=0, maxvalue=120)
)
