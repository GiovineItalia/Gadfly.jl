using Gadfly

set_default_plot_size(6inch, 3inch)

# make sure Stat.ticks work for categorical Geom.rectbin.

J=[-11.0935 -35.9819 12.2814; -9.71891 -31.852 11.2673; -8.51878 -28.1954 10.3279; -7.47033 -24.9582 9.45931; -6.55385 -22.0925 8.65728]
plotlabels=Any["n","vx","ax"]
spy(J, Gadfly.Scale.x_discrete(labels = i->plotlabels[i]))
