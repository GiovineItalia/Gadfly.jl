
using Gadfly, DataArrays

plot(x=rand(100), y=rand(100), shape=rand(1:8, 100),
     Geom.point)
