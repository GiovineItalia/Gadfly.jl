
using Gadfly, DataArrays, RDatasets

 plot(data("lattice", "singer"), x="VoicePart", y="Height", Geom.boxplot)
