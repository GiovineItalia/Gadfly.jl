using Gadfly, DataFrames, Compat, CSV

set_default_plot_size(6inch, 3inch)

plot(CSV.read(joinpath(dirname(@__DIR__), "data","issue120.csv")), x=:x1, y=:x2)
