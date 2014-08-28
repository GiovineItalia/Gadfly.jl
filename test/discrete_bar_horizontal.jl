
using RDatasets, DataArrays, Gadfly

plot(dataset("plm", "Cigar"), x=:Sales, y=:Year, Scale.y_discrete, Geom.bar(orientation=:horizontal))

