
using Gadfly, DataArrays, RDatasets

if VERSION < v"0.4-dev"
    using Dates
else
    using Base.Dates
end

approval = dataset("Zelig", "approval")
dates = Date[Date(y, m)
             for (y, m) in zip(approval[:Year], approval[:Month])]
approval[:Date] = dates

p = plot(approval, x="Date", y="Approve", Geom.line)


