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
plot(dataset("lattice", "melanoma"), x="Year", y="Incidence", Geom.line)
```

```julia
plot(dataset("Zelig", "approval"), x="Month",  y="Approve", color="Year", Geom.line)
```

We can use `preserve_order=true` to draw paths. Here's a random walk in 2D:

```julia
n = 500
srand(1234)
xjumps = rand(n)-.5
yjumps = rand(n)-.5
plot(x=cumsum(xjumps),y=cumsum(yjumps),Geom.line(preserve_order=true))
```

