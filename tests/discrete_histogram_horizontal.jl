
using RDatasets, DataArrays, Gadfly

plot(dataset("plm", "Cigar"), x=:Sales, y=:Year, Geom.bar(orientation=:horizontal))

