using DataFrames, Gadfly

set_default_plot_size(2*3.3inch, 2*3.3inch)

D = DataFrame(x1=[76.5763, 93.611, 67.2219, 39.6499],
              x2=[31.5112, 66.0929, 58.5162, 5.66118],
              x3=[27.0953, 11.2782, 16.7029, 47.3287],
              x4=[86.1758, 61.6317, 28.7841, 46.4209])

xsc  = Scale.x_continuous(minvalue=0.0, maxvalue=100)
ysc  = Scale.y_continuous(minvalue=0.0, maxvalue=100)

p1 = plot(D, x=:x1, y=:x2, xend=:x3, yend=:x4, Geom.segment(arrow=true), xsc, ysc);
p2 = plot(D, x=:x1, y=:x2, xend=:x3, yend=:x4, Geom.vector, xsc, ysc);

p3 = plot(z=(x,y)->x*exp(-(x^2+y^2)), 
        xmin=[-2], xmax=[2], ymin=[-2], ymax=[2], 
        Geom.vectorfield(scale=0.4, samples=17),
        Scale.x_continuous(minvalue=-2.0, maxvalue=2.0),
        Scale.y_continuous(minvalue=-2.0, maxvalue=2.0),
        Guide.xlabel("x"), Guide.ylabel("y"), Guide.colorkey(title="z"));

Z = fill(1.0, 5, 5)
Z[2:4, 2:4] .= 2.0
Z[3,3] = 3.0

p4 = plot(z=Z,
        Geom.vectorfield,
        Scale.x_continuous(minvalue=1.0, maxvalue=5.0),
        Scale.y_continuous(minvalue=1.0, maxvalue=5.0),
        Guide.xlabel("x"), Guide.ylabel("y"), 
        Theme(key_position=:none));

gridstack([p1 p2; p3 p4])
