using Gadfly, Distributions

set_default_plot_size(6inch, 3inch)

plot(x=rand(Rayleigh(2),1000), y=rand(Rayleigh(2),1000),
    Geom.density2d(levels = x->maximum(x)*0.5.^collect(1:2:8)), Geom.point,
    Theme(key_position=:none),
    Scale.color_continuous(colormap=x->colorant"red"))
