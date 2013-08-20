
using Gadfly
using RDatasets

plot(data("MASS", "mammals"), x="body", y="brain",
     label=1, Scale.x_log10, Scale.y_log10, Geom.point, Geom.label)


