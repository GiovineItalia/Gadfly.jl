
using Gadfly
using RDatasets

plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.beeswarm)
