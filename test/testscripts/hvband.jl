using Colors, Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)

Dp = dataset("ggplot2","presidential")[3:end,:]
De = dataset("ggplot2","economics")
De[:Unemploy] /= 10^3

p0 = plot(De, x=:Date, y=:Unemploy, Geom.line,
            layer(Dp, xmin=:Start, xmax=:End, Geom.vband, color=:Party),
            Scale.color_discrete_manual("deepskyblue", "lightcoral"),
            Coord.cartesian(xmin=Date("1965-01-01"), ymax=12),
            Guide.xlabel("Time"), Guide.ylabel("Unemployment (x10³)"), Guide.colorkey(title=""),
            Theme(default_color="black", key_position=:top));

p1 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point,
          layer(xmin=[5.0, 7.0], xmax=[6.5, 8.0] , Geom.vband, Theme(default_color="green")));

p2 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point,
          layer(ymin=[2.5, 3.6], ymax=[3.0, 4.0], Geom.hband, Theme(default_color="red")));

hstack(p0, p1, p2)
