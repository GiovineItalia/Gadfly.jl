
using Gadfly

plot(sin, 0, 25,
     xintercept=[0, pi, 2pi, 3pi],
     yintercept=[0, -1, 1],
     Geom.hline, Geom.vline)

