
using Gadfly, Datetime, RDatasets

approval = data("Zelig", "approval")
approval["date"] = Date[date(y, m)
                        for (y, m) in zip(approval["year"], approval["month"])]

p = plot(approval, x="date", y="approve", Geom.line)


