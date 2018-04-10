using DataFrames, Gadfly

set_default_plot_size(9inch, 3inch)

shapes = [Shape.square, Shape.diamond, Shape.cross, Shape.xcross, Shape.utriangle, Shape.dtriangle, 
    Shape.star1, Shape.star2, Shape.hexagon, Shape.octagon, Shape.hline, Shape.vline]

 D = DataFrame(x=[1:5; 1:4; 1:3], y=[5:-1:1; 4:-1:1; 3:-1:1], g=string.(1:12))

function plotf(coord::Coord.cartesian) 
    plot(D, coord,
        layer(x=:x, y=:y, style(default_color=colorant"black", point_size=2px), order=2),
        layer(x=:x, y=:y, shape=:g, color=:g, style(point_size=4mm, point_shapes=shapes)),
    Theme(key_position=:none, plot_padding=[0mm], background_color="white"))
end

coords = [Coord.cartesian(ymin=0, ymax=6), Coord.cartesian(xflip=true, ymin=0, ymax=6), Coord.cartesian(yflip=true, ymin=0, ymax=6)]
plots = plotf.(coords)
hstack(plots...)