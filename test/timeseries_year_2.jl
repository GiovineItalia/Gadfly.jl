
using Gadfly, DataArrays, Datetime, RDatasets

economics = dataset("HistData", "Prostitutes")
dates = Date[date(d) for d in economics[:Date]]

try
    economics[:Date] = dates
catch
    economics["Date"] = dates
end

p = plot(economics, x=:Date, y=:Count, Geom.line)

