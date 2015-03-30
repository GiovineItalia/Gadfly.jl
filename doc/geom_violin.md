---
title: violin
author: Daniel C. Jones
part: Geometry
order: 1016
...

Draw violin plots.

# Default Statistic

`Stat.violin`

# Aesthetics

Aesthetics used directly:

  * `x`: Group categorically on the X-axis
  * `y`: Y-axis position.
  * `width`: Density at a given `y` value.

With the default statistic `Stat.violin`, only the following need be defined:

  * `x` (optional): Group categorically on the X-axis.
  * `y`: Sample from which to draw the density plot.


# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.violin)
```



