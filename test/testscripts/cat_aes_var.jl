
# Issue #1228

using Gadfly

set_default_plot_size(6inch, 3inch)

y =  [0.15, 0.038, 0.5 , 0.24, 0.32, 0.48, 0.4, 0.036, 0.97, 0.3]

p1 = plot( layer(x=[5], y=[1.0], shape=[Shape.star1]),
    layer(x=1:10, y=y, shape=[Shape.circle], alpha=[0.1]),
    Theme(point_size=4pt, discrete_highlight_color=identity, key_position=:none) )

Zi = [(x,y) for x in -5:0.5:5, y in -5:0.5:5]
fn1(x) = x[1]*exp(-hypot(x[1]/3, x[2]/3)^2); fn2(x) = cos(hypot(x[1], x[2])/0.5)+1.0
i, ls = -5:0.5:5, 0.2:0.2:0.8
p2 = plot(Coord.cartesian(fixed=true),
    layer(z=fn2.(Zi), x=i, y=i, Geom.contour(levels=[1.0]), Theme(line_style=[:dash])),
    layer(z=fn1.(Zi), x=i, y=i, Stat.contour(levels=[-ls; ls]), Geom.polygon(fill=true)),
    Scale.color_continuous(minvalue=-1, maxvalue=1.0), Theme(lowlight_color=identity) 
)

hstack(p1, p2)
