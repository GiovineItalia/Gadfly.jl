
using Gadfly

set_default_plot_size(21cm, 8cm)

y = [0.46, 0.13, 0.4, 0.73, 0.43]

p1 = plot(x=[0,10], y=[0,1], Geom.blank)
p2 = plot()
p3 = push!(plot(), layer(x=1:5, y=y, Geom.point))

hstack(p1, p2, p3)
