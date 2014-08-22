#!/usr/bin/env julia

using Dates, Gadfly, DataFrames

a = [Date("2013-01-01"):day(1):Date("2014-01-01")]
b = [Date("2012-01-01"):day(1):Date("2016-01-01")]
ya = sin(0.01 * convert(Array{Float64}, a))
yb = cos(0.01 * convert(Array{Float64}, b))

df1 = DataFrame(
    x = a,
    y = ya,
    label = "first"
)

df2 = DataFrame(
    x = b,
    y = yb,
    label = "second"
)

df = vcat(df1, df2)

plot(df, x = :x, y = :y, color=:label, Geom.line)


