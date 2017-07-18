using DataFrames, Distributions, Gadfly

set_default_plot_size(8inch, 6inch)

df = DataFrame(
    RN = rand(1:100, 400),
    Dens = rand(Normal(450, 100), 400),
    Type = vcat(fill("Mature", 100),
                fill("MidU", 100),
                fill("MidT", 100),
                fill("Young", 100)))

pl = plot(df, x = "RN", y = "Dens",
         ygroup="Type",
         Theme(panel_stroke=colorant"grey", stroke_color=identity),
         Guide.xlabel("Cambial age (years)"),
         Guide.ylabel("Wood density (kg m<sup>3</sup>)"),
         Scale.x_continuous(minvalue=0, maxvalue=100, format=:plain),
         Scale.y_continuous(minvalue=300, maxvalue=900),
         Geom.subplot_grid(
             layer(Geom.point, Theme(default_color=colorant"gray")),
             layer(Geom.smooth, Theme(default_color=colorant"red")),
             Guide.xticks(ticks=[0, 25, 50, 75, 100])
         ))
