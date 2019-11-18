using Gadfly

set_default_plot_size(6inch, 3inch)

plot((x,y) -> x*exp(-(x-(round(Int, x)))^2-y^2), -8., 8, -2., 2)

