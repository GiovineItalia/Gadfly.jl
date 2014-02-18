
using Gadfly, DataArrays, Datetime, RDatasets

economics = dataset("ggplot2", "economics")
dates = Date[date(d) for d in economics[:Date]]

try
    economics[:Date] = dates
catch
    economics["Date"] = dates
end

p = plot(economics, x=:Date, y=:Unemploy, Geom.line)

