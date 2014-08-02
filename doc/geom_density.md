---
title: density
author: Daniel Jones
part: Geometry
order: 1001
...

Draw a kernel density estimate from data. An alias for `Geom.line` with
`Stat.density`.

# Aesthetics

  * `x`: Sample to draw density estimate from.

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.density)
```

```julia
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
```
