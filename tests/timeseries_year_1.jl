
using Gadfly, Datetime, RDatasets

economics = data("ggplot2", "economics")
economics["date"] = Date[date(d) for d in economics["date"]]


p = plot(economics, x="date", y="unemploy", Geom.line)

