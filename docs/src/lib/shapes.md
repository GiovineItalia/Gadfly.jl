```@meta
Author = "Ben J. Arthur"
```

# Shapes

Shapes, when combined with [Geom.point](@ref), specify the appearance of
markers.  Available shapes include circle, square, diamond, cross, xcross,
utriangle, dtriangle, star1, star2, hexagon, octogon, hline, and vline.

# Examples

```@setup 1
using RDatasets
using Gadfly
set_default_plot_size(12cm, 8cm)
```

```@example 1
plot(dataset("HistData","DrinksWages"),
    x="Wage", y="Drinks", shape=[Shape.square],
    Geom.point, Scale.y_log10)
```
