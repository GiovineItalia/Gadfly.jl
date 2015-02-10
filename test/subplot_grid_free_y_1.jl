
using Gadfly, RDatasets

plot(dataset("mlmRev", "Chem97"),
     x=:GCSEScore,
     ygroup=:Gender,
     xgroup=:Score,
     y=:Age,
     Geom.subplot_grid(Geom.point, free_y_axis=true),
     Theme(default_point_size=0.1mm, highlight_width=0.0mm))


