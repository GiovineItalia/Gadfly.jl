using Gadfly

set_default_plot_size(9inch, 3inch)

y, size = [0.55, 0.7, 0.9, 0.99, 0.9], [0.4, 0.5, 0.6, 0.68, 0.63]
juliaclrs = Gadfly.parse_colorant(["forestgreen", "brown3", "mediumorchid"])
theme = Theme(key_swatch_shape=Shape.circle, alphas=[0.1], discrete_highlight_color=identity)

p1 = plot(x=[2,1.13,2.87], y=[3,1.5,1.5], size=[0.75], alpha=[0.8],
    color=juliaclrs, Coord.cartesian(fixed=true))
p2 = plot(x=1:5, y=y, size=10^5*size, Scale.size_radius(maxvalue=10^5), theme)
p3 = plot(x=1:5, y=y, size=10^5*size, Scale.size_area(maxvalue=10^5), theme)

hstack(p1, p2, p3)
