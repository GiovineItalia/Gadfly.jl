
using Gadfly, DataArrays, DataFrames, Datetime, RDatasets

y = 1973
airquality = data("datasets", "airquality")
airquality["Date"] = Date[date(1973, m, d)
                          for (m, d) in zip(airquality["Month"], airquality["Day"])]
airquality = subset(airquality, :(Month .== 6))

p = plot(airquality, x="Date", y="Temp", Geom.line)



