# issue 462

using Gadfly
using Base.Dates

a = [unix2datetime(100)]
b = [10]

plot(x=a, y=b, Geom.point)
