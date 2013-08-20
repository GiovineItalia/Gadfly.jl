---
title: Geom.boxplot
author: Daniel Jones
order: 4
...

Draw boxplots.

# Default Stastitic

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

With default statistic `Stat.boxplot`, only the following aesthetics need b
defined:

  * `x` (optional): Group categorically on the X-axis.
  * `y`: Sample from which to draw the boxplot.


# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(data("lattice", "singer"), x="voice.part", y="height", Geom.boxplot)
```


