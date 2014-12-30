
using Gadfly, DataArrays, RDatasets

if VERSION < v"0.4-dev"
    using Dates
else
    using Base.Dates
end

economics = dataset("HistData", "Prostitutes")
# NOTE: I know these aren't unix times, but I'm not sure what they are, and this
# is just a test so it doesn't matter.
dates = DateTime[unix2datetime(d) for d in economics[:Date]]
economics[:Date] = dates

p = plot(economics, x=:Date, y=:Count, Geom.line)

