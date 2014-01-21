
using Gadfly, DataArrays, Datetime, RDatasets

economics = data("HistData", "Prostitutes")
economics["Date"] = Date[date(d) for d in economics["Date"]]

p = plot(economics, x="Date", y="Count", Geom.line)

