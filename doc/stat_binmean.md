---
title: qq
author: Matthieu Gomez
part: Statistic
order: 1005
...

Plot the mean of `y` against the mean of `x` within bins of `x`. 

# Aesthetics

  * `x`: Data to be plotted on the x-axis.
  * `y`: Data to be plotted on the y-axis.

# Arguments

  * `n`: Number of bins

# Examples

```{.julia hide="true" results="none"}
using Gadfly
using RDatasets
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
p1 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Stat.binmean, Geom.point)
```
