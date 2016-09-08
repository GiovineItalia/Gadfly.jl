```@meta
Author = "Matthieu Gomez"
```

# Stat.binmean

Plot the mean of `y` against the mean of `x` within `n` quantile bins of `x`.

## Aesthetics

  * `x`: Data to be plotted on the x-axis.
  * `y`: Data to be plotted on the y-axis.

## Arguments

  * `n`: Number of bins

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(12cm, 8cm)
```

```@example 1
p1 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Stat.binmean, Geom.point)
```
