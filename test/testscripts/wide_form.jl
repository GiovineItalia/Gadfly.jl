using Gadfly, RDatasets

set_default_plot_size(6inch, 4inch)

births = dataset("HistData", "Arbuthnot")

plot(births, x=Col.value(:Year), y=Col.value(:Males, :Females),
     color=Col.index(:Males, :Females), Geom.line)
