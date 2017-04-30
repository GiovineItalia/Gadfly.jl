
using Gadfly, DataArrays

plot(x=rand(100), y=rand(100), color=rand(1:8, 100),
     Geom.point)
