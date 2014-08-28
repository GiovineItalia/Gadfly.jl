
using Gadfly, RDatasets

plot(dataset("Zelig", "macro"), x=:Year, y=:Unem, color=:Country, Geom.point)

