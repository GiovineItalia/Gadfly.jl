using Gadfly, DataFrames, Compat

set_default_plot_size(6inch, 3inch)

plot(readtable(joinpath(dirname(@compat @__DIR__), "data","issue120.csv")), x=:x1, y=:x2)
