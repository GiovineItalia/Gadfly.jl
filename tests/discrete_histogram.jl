
using RDatasets, DataArrays, Gadfly

plot(dataset("plm", "Cigar"), x=:Year, y=:Sales, Geom.bar)

