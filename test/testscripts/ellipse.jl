using Distributions, Gadfly, Random
set_default_plot_size(6.6inch, 3.3inch)

Random.seed!(123)
d = rand(MvNormal([2, 2],[1.0 0.7; 0.7 1.0]), 50)'

pa= plot(x=d[:,1], y=d[:,2], Geom.point, layer(Stat.ellipse, Geom.polygon(preserve_order=true)))
pb= plot(x=d[:,1], y=d[:,2], Geom.point, Geom.ellipse(levels=[0.95, 0.99]))
hstack(pa,pb)
