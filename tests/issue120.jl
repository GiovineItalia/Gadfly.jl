
using Gadfly, DataFrames

plot(readtable("issue120.csv"), x="x1", y="x2")

