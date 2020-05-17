using DataFrames, Gadfly

set_default_plot_size(6inch, 3inch)

# using RDatasets
# plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP", Geom.rectbin)

D = DataFrame(x=[0.5,1], y=[0.5,1])
plot(D, x=:x, y=:y, Geom.rectbin)
