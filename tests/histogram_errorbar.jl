
using RDatasets, DataArrays, DataFrames, Gadfly

df = dataset("plm", "Cigar")
df = df[df[:State] .== 1, :]
ymin = df[:Sales] .- 20*rand()
ymax = df[:Sales] .+ 20*rand()

plot(df, x="Year", y="Sales", ymin=ymin, ymax=ymax,
     Geom.bar, Geom.errorbar)

