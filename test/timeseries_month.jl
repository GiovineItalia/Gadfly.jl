
using Gadfly, DataArrays, RDatasets

if VERSION < v"0.4-dev"
    using Dates
else
    using Base.Dates
end

y = 1973
airquality = dataset("datasets", "airquality")

dates = Date[Date(1973, m, d)
             for (m, d) in zip(airquality[:Month], airquality[:Day])]
airquality[:Date] = dates

p = plot(airquality, x=:Date, y=:Temp, Geom.line)



