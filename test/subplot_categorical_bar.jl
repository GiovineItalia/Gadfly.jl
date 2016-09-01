
using Gadfly


plot(xgroup=["A", "A", "B", "B"],
     x=["X", "Y", "X", "Y"],
     y=rand(4),
     Geom.subplot_grid(Geom.bar))

plot(x=rand(3),
     y=rand(3),
     xgroup=["A", "A", "B"],
     ygroup=["X", "Y", "Y"],
     Geom.subplot_grid(Geom.bar))
