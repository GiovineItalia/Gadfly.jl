using Gadfly, RDatasets

set_default_plot_size(6.6inch, 4inch)

quakes = dataset("datasets", "quakes")
quakes.Richter = floor.(Int, quakes.Mag) 
m = Matrix(quakes[:,[2,1]])
X = [ones(1000) m m.^2]
B = X'X \ X'quakes.Depth
fn(x,y) = ([1 x y x^2 y^2]*B)[1]

# p1 is an example of Scale.color2_identity
p1 = plot(quakes, x=:Depth, y=:Mag,
    layer(x=:Depth, y=:Mag, color2=[colorant"gray"], alpha=[0.3], size=[2pt]),
    layer(Geom.density2d(levels=7), order=1), Scale.color_continuous,
    Theme(key_position=:none)
)

p2 = plot(quakes,
    layer(x=:Long, y=:Lat, color2=:Richter, alpha=[0.7]),
    layer(fn, 165, 190, -40, 0, Stat.contour(levels=[0:250:1500;])),
    Scale.color_continuous(minvalue=0),
    Scale.color2_discrete(levels=[4,5,6]), 
    Guide.colorkey(title="Depth"),
    Theme(point_size=1.5pt, key_swatch_shape=Shape.circle, 
        discrete_highlight_color=c->nothing)
)

hstack(p1, p2)