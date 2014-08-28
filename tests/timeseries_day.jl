
using Gadfly, DataArrays, DataFrames, Dates, RDatasets

y = 1973
airquality = dataset("datasets", "airquality")

dates = Date[Date(1973, m, d)
             for (m, d) in zip(airquality[:Month], airquality[:Day])]

try
    airquality[:Date] = dates
catch
    airquality["Date"] = dates
end

airquality = airquality[airquality[:Month] .== 6, :]

p = plot(airquality, x=:Date, y=:Temp, Geom.line)



