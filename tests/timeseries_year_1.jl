
using Gadfly, DataArrays, Datetime, RDatasets

economics = data("ggplot2", "economics")
economics[:Date] = Date[date(d) for d in economics[:Date]]

p = plot(economics, x="Date", y="Unemploy", Geom.line)

