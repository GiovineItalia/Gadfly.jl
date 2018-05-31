# Shapes

## [`Shape.square`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
plot(dataset("HistData","DrinksWages"),
     x="Wage", y="Drinks", shape=[Shape.square],
     Geom.point, Scale.y_log10)
```
