
using Gadfly, DataArrays

plot(x=rand(100), y=rand(100), color=rand(["foo","bar"], 100),
     Geom.point)
