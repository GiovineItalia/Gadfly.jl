using Gadfly

p = plot(x=rand(10), y=rand(10),Theme(panel_stroke=colorant"black", tick_color=colorant"black"))
