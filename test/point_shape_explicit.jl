
using Gadfly, DataArrays

plot(x=rand(100), y=rand(100), shape=rand([circle,square,utriangle], 100),
     Geom.point)
