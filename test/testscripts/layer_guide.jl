using Gadfly

set_default_plot_size(6inch, 3inch)

plot(layer(x=[1,2,3], y=[4,5,6], Theme(default_color=colorant"red"), Geom.point),
     layer(x=[4,5,6], y=[1,2,3], Theme(default_color=colorant"blue"), Geom.point),
     Guide.XLabel("XLabel"), 
     Guide.YLabel("YLabel"),
     Guide.Title("Title")
     )
