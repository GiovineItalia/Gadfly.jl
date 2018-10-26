using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

plot(dataset("lattice", "singer"), x=:VoicePart, y=:Height,
     Geom.boxplot(suppress_outliers=true, method=[0.1, 0.2, 0.5, 0.8, 0.9]))
