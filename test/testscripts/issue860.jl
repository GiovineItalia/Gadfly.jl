using Gadfly

set_default_plot_size(7inch, 3inch)

p1 = plot(x=[0], y=[0], Scale.x_discrete, Geom.histogram2d)
p2 = plot(x=[0], y=[0], Scale.y_discrete, Geom.histogram2d)

hstack(p1, p2)
