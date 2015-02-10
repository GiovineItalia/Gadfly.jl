
using Gadfly, RDatasets

plot(dataset("mlmRev", "Chem97"),
     x=:GCSEScore,
     ygroup=:Age,
     color=:Gender,
     Geom.subplot_grid(Geom.histogram, free_y_axis=true))
