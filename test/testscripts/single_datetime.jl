# issue 462

using Gadfly, Dates

set_default_plot_size(6inch, 3inch)

a = [unix2datetime(100)]
b = [10]

plot(x=a, y=b, Geom.point)
