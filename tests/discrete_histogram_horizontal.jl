
using RDatasets, DataArrays, Gadfly

plot(data("plm", "Cigar"), x="Sales", y="Year", Geom.bar(orientation=:horizontal))

