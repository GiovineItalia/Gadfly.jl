
using Gadfly, DataArrays, RDatasets

plot(dataset("lattice", "singer"), x=:VoicePart, y=:Height, Geom.boxplot)
