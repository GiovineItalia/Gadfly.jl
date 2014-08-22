
using Gadfly, DataArrays, Dates, RDatasets

approval = dataset("Zelig", "approval")
dates = Date[Date(y, m)
             for (y, m) in zip(approval[:Year], approval[:Month])]
try
    approval[:Date] = dates
catch
    approval["Date"] = dates
end

p = plot(approval, x="Date", y="Approve", Geom.line)


