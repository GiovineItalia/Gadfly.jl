
using Gadfly

vstack(plot(sin, 0, 20, Coord.cartesian(xmin=2π, xmax=3π)),
       plot(sin, 0, 20, Coord.cartesian(ymin=-0.5, ymax=0.5)))

