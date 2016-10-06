
using Gadfly, Distributions

vals = rand(MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0]), 10000)
Gadfly.with_theme(:dark) do
    plot(x=vals[1,:], y=vals[2,:], Geom.hexbin)
end

