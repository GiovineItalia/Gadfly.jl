
using Gadfly, RDatasets

births = dataset("HistData", "Arbuthnot")

plot(births, x=Col.value(:Year), y=Col.value(:Males, :Females),
     color=Col.index(:Males, :Females), Geom.line)
