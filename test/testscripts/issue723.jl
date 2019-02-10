using Colors, Gadfly, RDatasets

set_default_plot_size(10cm, 8cm)

iris = dataset("datasets", "iris")
palettef = Scale.lab_gradient(range(HSV(250,1,1), stop=HSV(0,1,1), length=100)...)
colkey = Guide.colorkey(title="Petal\nlength")

plot(iris, x=:SepalLength, y=:SepalWidth, color=:PetalLength,
    shape=:Species, Guide.shapekey(pos=[4,8]), colkey,
    Scale.color_continuous(colormap=palettef, minvalue=0, maxvalue=7)
)

