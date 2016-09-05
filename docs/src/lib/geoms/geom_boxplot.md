```@meta
Author = "Daniel C. Jones"
```

# Geom.boxplot

Draw boxplots.

## Aesthetics

Aesthetics used directly:

  * `x`
  * `middle`
  * `lower_hinge`
  * `upper_hinge`
  * `lower_fence`
  * `upper_fence`
  * `outliers`

With default statistic [Stat.boxplot](@ref), only the following aesthetics need to be
defined:

  * `x` (optional): Group categorically on the X-axis.
  * `y`: Sample from which to draw the boxplot.


## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.boxplot)
```
