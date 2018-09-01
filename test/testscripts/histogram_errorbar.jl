using RDatasets, DataFrames, Gadfly

set_default_plot_size(6inch, 3inch)

df = dataset("plm", "Cigar")
df = df[df[:State] .== 1, :]
ymin = df[:Sales] .- 20*0.23603334566204692
ymax = df[:Sales] .+ 20*0.34651701419196046

plot(df, x="Year", y="Sales", ymin=ymin, ymax=ymax,
     Geom.bar, Geom.errorbar)
