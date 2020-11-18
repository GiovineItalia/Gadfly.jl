using Gadfly, DataFrames, CategoricalArrays

set_default_plot_size(6inch, 3inch)

a = DataFrame(diff = CategoricalArray([1,2,3,3,3,4,3,2]))
plot(a, x="diff", Geom.histogram)
