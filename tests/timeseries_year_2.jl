
using Gadfly, DataArrays, Dates, RDatasets

economics = dataset("HistData", "Prostitutes")
dates = Date[Date(d) for d in economics[:Date]]

try
    economics[:Date] = dates
catch
    economics["Date"] = dates
end

p = plot(economics, x=:Date, y=:Count, Geom.line)

