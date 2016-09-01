

using DataFrames, Gadfly


srand(123)
D = convert(DataFrame, 99*rand(4, 4)+0.5)

xsc  = Scale.x_continuous(minvalue=0.0, maxvalue=100)
ysc  = Scale.y_continuous(minvalue=0.0, maxvalue=100)

plot(D, x=:x1, y=:x2, xend=:x3, yend=:x4, Geom.segment(arrow=true), xsc, ysc)
plot(D, x=:x1, y=:x2, xend=:x3, yend=:x4, Geom.vector, xsc, ysc)

