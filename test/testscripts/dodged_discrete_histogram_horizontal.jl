using RDatasets, Gadfly

set_default_plot_size(6inch, 3inch)

plot(dataset("car", "SLID"), y=:Wages, color=:Language,
     Geom.histogram(position=:dodge, orientation=:horizontal))
