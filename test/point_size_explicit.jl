
using Gadfly, DataArrays

plot(x=rand(100), y=rand(100), size=rand([1mm, 2mm, 3mm], 100),
     Geom.point)
