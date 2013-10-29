---
title: Geom.histogram
author: Daniel Jones
part: Geometry
order: 6
...

Draw histograms. An alias for Geom.bar with Stat.histogram.

# Aesthetics

  * `x`: Sample to draw histogram from.
  * `color` (optional): Group categoricially by color.


# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(data("ggplot2", "diamonds"), x="price", Geom.histogram)
```

```julia
# Binding categorical data to color
plot(data("ggplot2", "diamonds"), x="price", color="cut", Geom.histogram)
```


