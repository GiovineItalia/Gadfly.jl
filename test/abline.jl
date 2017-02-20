
using Gadfly

plot(sin, 0, 25,
     yintercept=[0, -1, 1],
     xintercept=[0, pi, 2pi, 3pi, 0],
     yslope=[0, 0, 0, 0, 1],
     Geom.abline(color=["black","black","black","red","red","orange","orange","green"], size=2mm))

