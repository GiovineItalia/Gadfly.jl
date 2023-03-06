
using Distributions, Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
iris = dataset("datasets", "iris")
df = combine(groupby(iris, :Species), :SepalLength=>(x->fit(Normal, x))=>:Density)


gck = Guide.colorkey(title="", pos=[7, 2.0])

p1 = plot(df, y=:Density, color=:Species, gck,
    layer(Stat.unidistribution, Geom.line),
    layer(Stat.unidistribution([[0.0001, 0.05], [0.95, 0.9999]]), Geom.ribbon, alpha=[0.8]))
p2 = plot(df, y=:Density, group=:Species, gck,
    layer(Stat.unidistribution, Geom.line, color=[colorant"silver"]),
    layer(Stat.unidistribution([[0.0001, 0.1], [0.9, 0.9999]]), Geom.ribbon, alpha=[0.7]),
    Scale.color_discrete_manual("deepskyblue", "forestgreen"), Theme(lowlight_color=identity))
hstack(p1, p2)

