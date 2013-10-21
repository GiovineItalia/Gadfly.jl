
using Gadfly, Datetime, RDatasets

economics = data("HistData", "Prostitutes")
economics["date"] = Date[date(d) for d in economics["date"]]

p = plot(economics, x="date", y="count", Geom.line)

