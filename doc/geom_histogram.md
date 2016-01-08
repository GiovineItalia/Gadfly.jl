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

  * `position`: Either `:stack` or `:dodge`. If the `color` aesthetic is
    bound this determines how bars of different colors should be arranged:
    stacked on top of each other, or placed side by side.
  * `orientation`: Either `:vertical` (default) or `:horizontal`. If
    `:horizontal`, then the required aesthetic is `y` instead of `x`.
  * `bincount`: Number of bins to use. If unspecified, an optimization method
    is used to determine a reasonable value.
  * `minbincount`: Set a lower limit when automatically choosing a bin count.
  * `maxbincount`: Set an upper limit when automatically choosing a bin count.
  * `density`: If true, use density rather that counts.

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.histogram)
```

```julia
# Binding categorical data to color
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.histogram)
```

```julia
# Choosing a smaller bin count
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut",
     Geom.histogram(bincount=30))
```

```julia
# Density instead of counts
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut",
     Geom.histogram(bincount=30, density=true))
```
