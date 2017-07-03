using Gadfly, DataFrames

t = DataFrame(x=[:b,:b,:b,:b,:b,:b], y=[2,2,2,2,2,2])
plot(t, x=:x, y=:y, Geom.beeswarm)
