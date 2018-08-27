using RDatasets, Gadfly

set_default_plot_size(6inch, 3inch)

plot(dataset("plm", "Cigar"), x=:Year, y=:Sales, Scale.x_discrete, Geom.bar)
