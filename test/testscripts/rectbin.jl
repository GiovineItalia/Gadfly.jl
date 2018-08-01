using DataFrames, Gadfly

set_default_plot_size(6inch, 3inch)

# using RDatasets
# plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP", Geom.rectbin)

D = DataFrame(x=[0.5,1], y=[0.5,1], x1=[0,0.5], y1=[0,0.5], x2=[1,1.5], y2=[1,1.5])
pa = plot(D, x=:x, y=:y, Geom.rectbin)
