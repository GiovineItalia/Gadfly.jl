---
title: smooth
author: Daniel Jones
part: Geometry
order: 1010
...

Plot a smooth function estimated from data. An alias for `Geom.line` with `Stat.smooth`.

# Aesthetics

  * `x`: Predictor data.
  * `y`: Response data.
  * `color`: (optional) Group categorically by color.

# Arguments

  * `method`: Currently only `:loess` is supported.
  * `smoothing`: Method specific parameter controlling the degree of smoothing.
    For loess, this is the span parameter giving the proportion of data
    used for each local fit.

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(16cm, 10cm)
```

```julia
plot(data("Zelig", "macro"), x="year", y="unem", color="country", Geom.point, Geom.smooth)
```
