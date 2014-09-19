
using Gadfly, DataArrays, RDatasets

if VERSION < v"0.4-dev"
    using Datetime
else
    date = Date
end

approval = dataset("Zelig", "approval")
dates = Date[date(y, m)
             for (y, m) in zip(approval[:Year], approval[:Month])]
approval[:Date] = dates

p = plot(approval, x="Date", y="Approve", Geom.line)


