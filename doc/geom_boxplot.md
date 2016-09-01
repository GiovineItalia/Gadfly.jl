---
title: boxplot
author: Daniel Jones
part: Geometry
order: 1000
...

Draw boxplots.

# Default Statistic

`Stat.boxplot`

# Aesthetics

Aesthetics used directly:

  * `x`
  * `middle`
  * `lower_hinge`
  * `upper_hinge`
  * `lower_fence`
  * `upper_fence`
  * `outliers`

With default statistic `Stat.boxplot`, only the following aesthetics need to be
defined:

  * `x` (optional): Group categorically on the X-axis.
  * `y`: Sample from which to draw the boxplot.


# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.boxplot)
```


