
using RDatasets
using Gadfly

plot(data("plm", "Cigar"), x="year", y="sales", Geom.bar)

