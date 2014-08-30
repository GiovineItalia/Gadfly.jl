
using Gadfly

plot(x=rand(20), y=rand(20), color=vcat(fill("A", 10), fill("B", 10)),
     Guide.colorkey("Species"))

