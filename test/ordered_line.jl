using Gadfly

t = [0:0.2:2pi;]
plot(x=cos.(t), y=sin.(t), Geom.line(preserve_order=true))
plot(x=cos.(t), y=sin.(t), Geom.path)
