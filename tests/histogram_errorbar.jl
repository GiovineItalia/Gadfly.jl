
using RDatasets, DataFrames, Gadfly

df = subset(data("plm", "Cigar"), :(state .== 1))
ymin = df["sales"] .- 20*rand()
ymax = df["sales"] .+ 20*rand()

plot(df, x="year", y="sales", ymin=ymin, ymax=ymax,
     Geom.bar, Geom.errorbar)

