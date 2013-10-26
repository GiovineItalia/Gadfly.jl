
using Gadfly, RDatasets

plot(data("Zelig", "macro"), x="year", y="country", color="gdp", Geom.rectbin)
