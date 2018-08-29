using Gadfly, RDatasets, Dates

set_default_plot_size(6inch, 3inch)

economics = dataset("HistData", "Prostitutes")
p = plot(economics, x=:Date, y=:Count, Geom.line)
