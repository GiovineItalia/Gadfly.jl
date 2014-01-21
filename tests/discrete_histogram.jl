
using RDatasets, DataArrays, Gadfly

plot(data("plm", "Cigar"), x="Year", y="Sales", Geom.bar)

