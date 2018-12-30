using Colors, Gadfly, RDatasets

set_default_plot_size(5inch,4inch)
iris = dataset("datasets","iris")

p = plot(iris, x=:SepalLength, y=:PetalLength, color=:Species, Geom.point,
     layer(Stat.smooth(method=:lm, levels=[0.90, 0.99]), Geom.line, Geom.ribbon), 
    Theme(lowlight_color=c->RGBA{Float32}(c.r, c.g, c.b, 0.2),
        key_position=:inside)
)
