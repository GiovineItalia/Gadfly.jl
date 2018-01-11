using Gadfly, DataArrays, DataFrames

set_default_plot_size(6inch, 3inch)

a = DataFrame(diff = CategoricalArray(Float64[1,2,3,3,3,4,3,2]))
plot(a, x="diff", Geom.histogram)
