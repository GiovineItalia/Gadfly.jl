
using Gadfly


plot(xgroup=["A", "A", "B", "B"],
     x=["X", "Y", "X", "Y"],
     y=rand(4),
     Geom.subplot_grid(Geom.bar))


