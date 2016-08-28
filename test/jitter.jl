
using Gadfly, DataArrays, RDatasets

plot(dataset("datasets", "iris"), x=:SepalLength, y=:SepalWidth, color=:Species,
     Stat.x_jitter, Stat.y_jitter, Geom.point)

# make sure type-coercion works properly, the `y` values here are integers
# but will be coerced into floats.
plot(x=rand(500), y=rand(1:4, 500), Stat.y_jitter(range=0.5), Geom.point)
