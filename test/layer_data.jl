
using Gadfly, DataFrames

df1 = DataFrame(x=[1,2,3], y=[1, 2, 3])
df2 = DataFrame(x=[2, 4, 6], y=[2, 4, 6])

plot(df1, x=:x, y=:y, layer(df2, Geom.point))


