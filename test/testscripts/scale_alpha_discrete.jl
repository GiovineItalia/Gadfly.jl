using DataFrames, Gadfly

set_default_plot_size(21cm, 8cm)

D = DataFrame(x=1:6, y=[0.39, 0.26, 0.31, 0.43, 0.1, 0.78], Shape=repeat(["a","b","c"], outer=2))
coord = Coord.cartesian(xmin=0, xmax=7, ymin=0, ymax=1.0)
p1 = plot(D, x=:x, y=:y, color=:x,  coord,
    Scale.color_discrete, Geom.point, Geom.hair,
    Guide.title("Scale.color_discrete, Theme(alphas=[0.5])"),
    Theme(alphas=[0.5], discrete_highlight_color=identity,
        point_size=2mm)
)
p2 = plot(D, x=:x, y=:y, alpha=:x, shape=:Shape, coord,
    Scale.alpha_discrete, Geom.point, Geom.hair,
    Guide.title("Scale.alpha_discrete, Theme(default_color=\"green\")"),
    Theme(default_color="green",   discrete_highlight_color=c->"gray",
        point_size=2mm, alphas=[0.0,0.2,0.4,0.6,0.8,1.0])
)
hstack(p1,p2)