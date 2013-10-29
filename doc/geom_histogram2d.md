---
title: Geom.histogram2d
author: Daniel Jones
part: Geometry
order: 8
...


Bin data in rectangles and indicate density with color. As in heatmaps, etc.

An alias for `Geom.rectbin` with `Stat.histogram2d`.

# Aesthetics
  * x
  * y


# Examples


```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```


```julia
plot(data("car", "Womenlf"), x="hincome", y="region", Geom.histogram2d)
```


```julia
plot(data("car", "UN"), x="gdp", y="infant.mortality",
     Scale.x_log10, Scale.y_log10, Geom.histogram2d)
```


