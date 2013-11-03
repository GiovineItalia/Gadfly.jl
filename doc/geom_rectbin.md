---
title: rectbin
author: Daniel Jones
part: Geometry
order: 1009
...

Draw colored rectangles.

# Aesthetics
  * color

Either

  * x_min
  * x_max
  * y_min
  * y_max

Or

  * x
  * y

In the former case, an rectangles defined by `x_min`, `x_max`, `y_min`, `y_max`
are drawn, in the latter, equal sizes sequares are centered at `x` and `y`
positions.

# See Also

  * `Geom.histogram2d`

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```


```julia
plot(data("Zelig", "macro"), x="year", y="country", color="gdp", Geom.rectbin)
```

