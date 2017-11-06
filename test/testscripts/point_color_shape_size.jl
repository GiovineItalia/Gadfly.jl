using Gadfly

set_default_plot_size(6inch, 6inch)

plot(x=rand(100), y=rand(100),
     color=rand([colorant"red",colorant"blue",colorant"green"], 100),
     shape=rand([Shape.circle,Shape.square,Shape.utriangle], 100),
     size=rand([1mm, 2mm, 3mm], 100),
     Geom.point)
