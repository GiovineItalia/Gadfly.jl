using Gadfly

set_default_plot_size(6inch, 6inch)

plot(x=rand(100), y=rand(100), size=rand(["foo","bar","pooh"], 100), Geom.point)
