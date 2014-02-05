
using Gadfly, DataArrays, Datetime, RDatasets

approval = data("Zelig", "approval")
approval["Date"] = Date[date(y, m)
                       for (y, m) in zip(approval[:Year], approval[:Month])]

p = plot(approval, x="Date", y="Approve", Geom.line)


