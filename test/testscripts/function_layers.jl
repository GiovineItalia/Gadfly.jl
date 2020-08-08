using Gadfly, RDatasets

set_default_plot_size(5inch, 3inch)

iris = dataset("datasets", "iris")

fs = [ x->0.3x+1, x->0.3x+1.1 ]
cs = ["versicolor", "virginica"]
plot(iris,
  layer(x=:SepalLength, y=:SepalWidth, color=:Species),
  layer(fs, 4, 8, color=cs, order=2)
)
