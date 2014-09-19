
using Gadfly, DataArrays, RDatasets

if VERSION < v"0.4-dev"
    using Datetime
else
    date = Date
end

economics = dataset("HistData", "Prostitutes")
dates = Date[date(d) for d in economics[:Date]]
economics[:Date] = dates

p = plot(economics, x=:Date, y=:Count, Geom.line)

