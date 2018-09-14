using RDatasets, Gadfly

set_default_plot_size(6inch, 3inch)

plot(dataset("car", "Womenlf"), x=:HIncome, y=:Region, Geom.histogram2d)
