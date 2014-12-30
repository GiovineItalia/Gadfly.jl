
# issue 462

using Gadfly

if VERSION < v"0.4-dev"
    using Dates
else
    using Base.Dates
end

a = [unix2datetime(100)]
b = [10]

plot(x=a, y=b, Geom.point)

