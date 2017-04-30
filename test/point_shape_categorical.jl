
using Gadfly, DataArrays

plot(x=rand(100), y=rand(100), shape=rand(["foo","bar","pooh"], 100),
     Geom.point)
