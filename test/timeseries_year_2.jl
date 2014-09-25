
using Gadfly, DataArrays, RDatasets

if VERSION < v"0.4-dev"
    using Dates
else
    using Base.Dates
end

economics = dataset("HistData", "Prostitutes")
dates = Date[Date(d) for d in economics[:Date]]
economics[:Date] = dates

p = plot(economics, x=:Date, y=:Count, Geom.line)

