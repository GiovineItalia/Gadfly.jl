using Gadfly, DataArrays, RDatasets
using Base.Dates

approval = dataset("Zelig", "approval")
dates = Date[Date(y, m)
             for (y, m) in zip(approval[:Year], approval[:Month])]
approval[:Date] = dates

p = plot(approval, x="Date", y="Approve", Geom.line)
