using Compose, DataFrames, Gadfly

set_default_plot_size(9inch, 3.3inch)

theme1 = Theme(point_size=3mm)
coord1 = Coord.cartesian(xmin=0.0, xmax=6.0)
D = DataFrame(x=1:5,
              y=[0.768448, 0.940515, 0.673959, 0.395453, 0.313244],
              V1=["A","A","B","B","D"],
              V2 = string.([1,2,2,3,3])  )

pa = plot(x=1:5, y=[0.77, 0.94, 0.67, 0.39, 0.31], shape=["A","A","B","B","D"], theme1, coord1,
    Guide.shapekey(title="Key",labels=["α","β","δ"]),
    Guide.title("Guide.shapekey") )

pb = plot(D, x=:x, y=:y, shape=:V1, color=:V1,
        Scale.shape_discrete(levels=["D","A","B"]),     
        theme1, coord1, Guide.title("Shape==Color") )

pc = plot(D, x=:x, y=:y, shape=:V1, color=:V2,  coord1,
        Guide.colorkey(title="Color"),
        Guide.shapekey(title="Shape ", pos=[0.74w,-0.27h]),
        Theme(point_size=3mm, key_swatch_color="slategrey"),
        Guide.title("Shape!=Color") )

hstack(pa,pb,pc)
