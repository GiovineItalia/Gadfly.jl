
using DataFrames
df = DataFrame()
df[:pb]=rand(1:50, 50);
df[:t]=rand(1:50, 50);
df[:h]=[0.0 for i in 1:50];

using Gadfly
plot(df, x = :pb, y = :t, color = :h, Geom.rectbin)


