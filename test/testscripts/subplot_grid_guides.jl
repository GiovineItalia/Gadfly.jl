
using Gadfly, RDatasets

set_default_plot_size(14cm, 8cm)

haireye = dataset("datasets","HairEyeColor")
palette = ["brown","blue","tan","green"]

plot(haireye, y=:Sex, x=:Freq, color=:Eye, ygroup=:Hair,
  Geom.subplot_grid(Geom.bar(position=:stack, orientation=:horizontal),
        Guide.ylabel(orientation=:vertical) ),
    Scale.color_discrete_manual(palette...),
    Guide.colorkey(title="Eye\ncolor"),
    Guide.ylabel("Hair color"), Guide.xlabel("Frequency")
)

