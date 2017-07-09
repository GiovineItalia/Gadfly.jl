using Gadfly

# wide-form plotting of heterogenous arrays of arrays

set_default_plot_size(4inch, 4inch)

xs = [ rand(Float32, 10),
       rand(Float64, 15),
       rand(Float32, 5) ]
plot(xs, x=Row.index, y=Col.value, color=Col.index, Scale.color_discrete, Geom.line)
