using Gadfly, RDatasets

set_default_plot_size(6inch, 2inch)

plot(dataset("Zelig", "macro"), x=:Year, y=:Unem, color=:Country, Geom.point)
