using DataFrames, Gadfly

set_default_plot_size(2*3.3inch, 2*3.3inch)

srand(123)
D = convert(DataFrame, 99*rand(4, 4)+0.5)

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
Z[2:4, 2:4] = 2.0
Z[3,3] = 3.0

p4 = plot(z=Z,
        Geom.vectorfield,
        Scale.x_continuous(minvalue=1.0, maxvalue=5.0),
        Scale.y_continuous(minvalue=1.0, maxvalue=5.0),
        Guide.xlabel("x"), Guide.ylabel("y"), 
        Theme(key_position=:none));

gridstack([p1 p2; p3 p4])
