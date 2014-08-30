
using Gadfly, DataArrays, RDatasets

plot(dataset("car", "UN"), x=:GDP, y=:InfantMortality,
     Geom.histogram2d, Scale.x_log10, Scale.y_log10)

