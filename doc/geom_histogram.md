---
title: histogram
author: Daniel Jones
part: Geometry
order: 1003
...

Draw histograms. An alias for `Geom.bar` with `Stat.histogram`.

# Aesthetics

  * `x`: Sample to draw histogram from.
  * `color` (optional): Group categoricially by color.


# Arguments

  * `position`: Either `:stacked` or `:dodged`. If the `color` aesthetic is
    bound this determines how bars of different colors should be arranged:
    stacked on top of each other, or placed side by side.
  * `bincount`: Number of bins to use. If unspecified, an optimization method
    be used to deterimine a reasonable value.
  * `minbincount`: Set a lower limit when automatically choosing a bin count.
  * `maxbincount`: Set an upper limit when automatically choosing a bin count.

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(data("ggplot2", "diamonds"), x="price", Geom.histogram)
```

```julia
# Binding categorical data to color
plot(data("ggplot2", "diamonds"), x="price", color="cut", Geom.histogram)
```

```julia
# Choosing a smaller bin count
plot(data("ggplot2", "diamonds"), x="price", color="cut",
     Geom.histogram(bincount=30))
```

