using Gadfly, DataFrames

set_default_plot_size(6inch, 3inch)

t = DataFrame(x=[:b,:b,:b,:b,:b,:b], y=[2,2,2,2,2,2])
plot(t, x=:x, y=:y, Geom.beeswarm)
