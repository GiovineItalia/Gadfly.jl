---
title: bar
author: Daniel Jones
part: Geometry
order: 1003
...

Draw bar plots. This geometry works on pre-summarized data such as counts. To
draw histograms from a series of observations, add `Stat.histogram` to the plot,
or use the convenient geometry `Geom.histogram`.

# Aesthetics

  * `y`: Height of each bar.
  * `color` (optional): Group categorically by color.

Either

  * `x`: Position of each bar.

Or

  * `xmin`: Starting x positions for each bar.
  * `xmax`: End x positions for each bar.

If `x` is given, a bar will be drawn at each x value, specifying both `xmin` and
`xmax` allows bars of variable width to be drawn.

# Arguments

  * `position`: Either `:stack` or `:dodge`. If the `color` aesthetic is
    bound this determines how bars of different colors should be arranged:
    stacked on top of each other, or placed side by side.

  * `orientation`: Either `:vertical` (default) or `:horizontal`. If
    `:horizontal`, then the required aesthetics are `y` or `ymin/ymax`.

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(12cm, 8cm)
```

```julia
plot(dataset("HistData", "ChestSizes"), x="Chest", y="Count", Geom.bar)
```


