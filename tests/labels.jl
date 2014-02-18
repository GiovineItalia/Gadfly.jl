
using Gadfly, DataArrays, RDatasets

plot(dataset("MASS", "mammals"), x="Body", y="Brain",
     label=1, Scale.x_log10, Scale.y_log10, Geom.point, Geom.label)


