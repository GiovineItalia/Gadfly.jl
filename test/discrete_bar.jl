
using RDatasets, DataArrays, Gadfly

plot(dataset("plm", "Cigar"), x=:Year, y=:Sales, Scale.x_discrete, Geom.bar)

