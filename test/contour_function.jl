
using Gadfly, Compat

plot((x,y) -> x*exp(-(x-(@compat round(Int, x)))^2-y^2), -8., 8, -2., 2)


