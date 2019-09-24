using RDatasets, Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)

D = dataset("datasets","faithful")
D.g = D.Eruptions.>3.0

coord = Coord.cartesian(ymin=35, ymax=100)

pa = plot(D, coord,
    x=:Eruptions, y=:Waiting, group=:g,
    Geom.point, Geom.ellipse
)
pb = plot(D, coord,
    x=:Eruptions, y=:Waiting, color=:g,
    Geom.point, Geom.ellipse,
    layer(Geom.ellipse(levels=[0.99]), style(line_style=[:dot])),
    style(key_position=:none), Guide.ylabel(nothing)
)
hstack(pa,pb)