using Gadfly, DataFrames

plot(readtable(Pkg.dir("Gadfly", "test", "issue120.csv")), x=:x1, y=:x2)

