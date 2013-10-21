
using Gadfly, DataFrames, Datetime, RDatasets

y = 1973
airquality = data("datasets", "airquality")
airquality["date"] = Date[date(1973, m, d)
                          for (m, d) in zip(airquality["Month"], airquality["Day"])]
airquality = subset(airquality, :(Month .== 6))

p = plot(airquality, x="date", y="Temp", Geom.line)



