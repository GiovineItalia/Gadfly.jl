
using Gadfly, DataArrays, RDatasets

plot(data("Zelig", "macro"), x="Year", y="Country", color="GDP", Geom.rectbin)
