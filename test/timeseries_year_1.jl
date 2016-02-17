using Gadfly, DataArrays, RDatasets
using Base.Dates

economics = dataset("ggplot2", "economics")
dates = Date[Date(d) for d in economics[:Date]]
economics[:Date] = dates

p = plot(economics, x=:Date, y=:Unemploy, Geom.line)
