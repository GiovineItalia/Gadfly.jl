
using Gadfly

plot(layer(y=20*rand(20), Geom.bar), layer(x=20*rand(20), Geom.line))
