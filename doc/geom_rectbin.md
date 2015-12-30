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

In the former case, rectangles defined by `x_min`, `x_max`, `y_min`, `y_max`
are drawn, in the latter, equal sizes squares are centered at `x` and `y`
positions.

# See Also

  * `Geom.histogram2d`

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```


```julia
plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP", Geom.rectbin)
```

