using Gadfly, DataFrames

plot(readtable(joinpath(dirname(@__FILE__), "issue120.csv")), x=:x1, y=:x2)
