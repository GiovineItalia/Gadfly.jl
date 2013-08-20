---
title: Geom.line
author: Daniel Jones
order: 3
...


# Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `color` (optional): Group categorically by color.

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(data("lattice", "melanoma"), x="year", y="incidence", Geom.line)
```

```julia
plot(data("Zelig", "approval"), x="month",  y="approve", color="year", Geom.line)
```

