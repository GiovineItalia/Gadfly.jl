using DataFrames, Gadfly

set_default_plot_size(9inch, 3inch)

shapes = [Shape.square, Shape.diamond, Shape.cross, Shape.xcross, Shape.utriangle, Shape.dtriangle, 
    Shape.star1, Shape.star2, Shape.hexagon, Shape.octagon, Shape.hline, Shape.vline, 
    Shape.ltriangle, Shape.rtriangle]

D = DataFrame(x=[1:5; 1:4; 1:3; 1:2], y=[5:-1:1; 4:-1:1; 3:-1:1; 2:-1:1], g=string.(1:14))

function plotf(coord::Coord.cartesian) 
    plot(D, coord,
        layer(x=:x, y=:y, Theme(default_color="black", point_size=2px)),
        layer(x=:x, y=:y, shape=:g, color=:g, Geom.point),
    Theme(point_shapes=shapes, key_position=:none, point_size=4mm,
     plot_padding=[0mm], background_color="white") )
end

coords = [Coord.cartesian(xflip=xf, yflip=yf, xmin=0, xmax=6, ymin=0, ymax=6) 
    for (xf, yf) in zip([false, true, false], [false, false, true]) ]
plots = plotf.(coords)
hstack(plots...)
