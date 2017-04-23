
using Gadfly, DataArrays

plot(x=rand(100), y=rand(100), color=rand([colorant"red",colorant"blue"], 100),
     Geom.point)
