
using Gadfly, RDatasets

plot(data("car", "UN"), x="gdp", y="infant.mortality",
     Geom.histogram2d, Scale.x_log10, Scale.y_log10)

