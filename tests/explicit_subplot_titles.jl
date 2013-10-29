
using Gadfly

plot(x=rand(20), y=rand(20), xgroup=vcat(fill("A", 10), fill("B", 10)),
     Geom.subplot_grid(Geom.point),
     Guide.xlabel("Species"),
     Guide.ylabel("Important Measurements"))
