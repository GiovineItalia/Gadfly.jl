using Gadfly

set_default_plot_size(6inch, 6inch)

z = rand(["foo","bar","pooh"], 100)
plot(x=rand(100), y=rand(100), shape=z, Geom.point,
    Scale.shape_discrete(levels=sort(unique(z))))
