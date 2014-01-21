
using RDatasets, DataArrays, DataFrames, Gadfly

df = subset(data("plm", "Cigar"), :(State .== 1))
ymin = df["Sales"] .- 20*rand()
ymax = df["Sales"] .+ 20*rand()

plot(df, x="Year", y="Sales", ymin=ymin, ymax=ymax,
     Geom.bar, Geom.errorbar)

