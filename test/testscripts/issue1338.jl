using DataFrames, Gadfly

set_default_plot_size(6.6inch,3.3inch)

y = [0.71, 0.88, 0.97, 0.8, 0.16, 0.12, 0.52, 0.52, 0.67, 0.31]
df = DataFrame(x=repeat(1:5,2), y=y, z=repeat(["a","b"], inner=5))

stylef(shape::Function) = style(point_shapes=[shape], point_size=2mm)
p2 = plot( layer(x=1:10, y=y, stylef(Shape.cross)),
    layer(x=1:10, y=y.+0.3, stylef(Shape.xcross)) )

p3 = plot(df, xgroup=:z, x=:x, y=:y, shape=[Shape.square], alpha=[0.1],
    Geom.subplot_grid(Geom.point), 
    Theme(point_size=5pt, key_position=:none, discrete_highlight_color=identity) )
    
hstack(p2, p3)
   