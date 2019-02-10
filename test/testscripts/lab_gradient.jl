using Gadfly

set_default_plot_size(21cm, 8cm)

# Issue #678

x = repeat(collect(1:10), inner=[10]) .-0.5
y = repeat(collect(1:10), outer=[10]) .-0.5
palettef1 = Scale.lab_gradient(colorant"green", colorant"white", colorant"red")
palettef2 = Scale.lab_gradient(["blue", "ghostwhite","red"]...)
p1 = plot(x=x,y=y,color=x+y, Geom.rectbin, Scale.ContinuousColorScale(palettef1))
p2 = plot(x=x,y=y,color=x+y, Geom.rectbin, Scale.ContinuousColorScale(palettef2))
hstack(p1, p2)