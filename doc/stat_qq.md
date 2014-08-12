---
title: qq
author: Dave Kleinschmidt
part: Statistic
order: 1001
...

Generates quantile-quantile plots for `x` and `y`.  If each is a numeric vector,
their sample quantiles will be compared.  If one is a `Distribution`, then its
theoretical quantiles will be compared with the sample quantiles of the other.

# Aesthetics

  * `x`: Data or `Distribution` to be plotted on the x-axis.
  * `y`: Data or `Distribution` to be plotted on the y-axis.

# Examples

```{.julia hide="true" results="none"}
using Gadfly, Distributions

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
srand(1234)
```

```julia
plot(x=rand(Normal(), 100), y=rand(Normal(), 100), Stat.qq, Geom.point)
plot(x=rand(Normal(), 100), y=Normal(), Stat.qq, Geom.point)
```
