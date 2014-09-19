
using Gadfly, DataArrays, DataFrames, RDatasets

if VERSION < v"0.4-dev"
    using Datetime
else
    date = Date
end

y = 1973
airquality = dataset("datasets", "airquality")

dates = Date[date(1973, m, d)
             for (m, d) in zip(airquality[:Month], airquality[:Day])]

airquality[:Date] = dates

airquality = airquality[airquality[:Month] .== 6, :]

p = plot(airquality, x=:Date, y=:Temp, Geom.line)



