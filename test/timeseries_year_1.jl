
using Gadfly, DataArrays, RDatasets

if VERSION < v"0.4-dev"
    using Dates
else
    using Base.Dates
end

economics = dataset("ggplot2", "economics")
dates = Date[Date(d) for d in economics[:Date]]
economics[:Date] = dates

p = plot(economics, x=:Date, y=:Unemploy, Geom.line)

