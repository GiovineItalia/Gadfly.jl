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


## Arguments

  * `suppress_outliers`: If true, don't draw points indicating outliers. (Default is false.)
  * `method`: How boxplot statistics are computed. Either `:tukey` (default)
    which uses Tukey's rule (i.e. fences are 1.5 times inter-quartile range), or
    a vector of 5 numbers giving quantiles for lower fence, lower hinge, middle,
    upper hinge, and upper fence in that order.


## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.boxplot)
```
