using Gadfly, DataArrays

set_default_plot_size(6inch, 3inch)

spy(randn((10, 10)), Coord.cartesian(fixed=true))
