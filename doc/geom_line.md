---
title: line
author: Daniel Jones
part: Geometry
order: 1007
...


# Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `color` (optional): Group categorically by color.


# Arguments

  * `preserve_order`: Default behavior for `Geom.line` is to draw lines between
    points in order along the x-axis. If this option is true, lines will be
    drawn between points in the order they appear in the data.


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

