using DataFrames, Gadfly

set_default_plot_size(21cm, 8cm)


D = DataFrame(x=1:10, y=[0.11, 0.2, 0.1, 0.15, 0.3, 0.45, 0.37, 0.81, 0.62, 0.5])
palettef = Scale.lab_gradient("darkgreen","orange", "blue")
p1 = plot(D, x=:x, y=:y, color=:x, Geom.point,  
    Scale.color_continuous(colormap=palettef, minvalue=0, maxvalue=10),
    Guide.title("Scale.color_continuous, Theme(alphas=[0.5])"),
    Theme(alphas=[0.5], continuous_highlight_color=identity,
        point_size=2mm)
)
p2 = plot(D, x=:x, y=:y, alpha=:x, Geom.point,  
    Scale.alpha_continuous(minvalue=0, maxvalue=10),
    Guide.title("Scale.alpha_continuous, Theme(default_color=\"blue\")"),
    Theme(default_color="blue", discrete_highlight_color=c->"gray",
        point_size=2mm)
)
hstack(p1, p2)