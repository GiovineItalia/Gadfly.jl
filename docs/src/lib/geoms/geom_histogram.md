```@meta
Author = "Daniel C. Jones"
```

# Geom.histogram

Draw histograms. An alias for [Geom.bar](@ref) with [Stat.histogram](@ref).

## Aesthetics

  * `x`: Sample to draw histogram from.
  * `color` (optional): Group categoricially by color.


## Arguments

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

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.histogram)
```

```@example 1
# Binding categorical data to color
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.histogram)
```

```@example 1
# Choosing a smaller bin count
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut",
     Geom.histogram(bincount=30))
```

```@example 1
# Density instead of counts
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut",
     Geom.histogram(bincount=30, density=true))
```
