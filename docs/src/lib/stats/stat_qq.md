```@meta
Author = "Dave Kleinschmidt"
```

# Stat.qq

Generates quantile-quantile plots for `x` and `y`.  If each is a numeric vector,
their sample quantiles will be compared.  If one is a `Distribution`, then its
theoretical quantiles will be compared with the sample quantiles of the other.

## Aesthetics

  * `x`: Data or `Distribution` to be plotted on the x-axis.
  * `y`: Data or `Distribution` to be plotted on the y-axis.

## Examples

```@setup 1
using Distributions
using Gadfly
Gadfly.set_default_plot_size(12cm, 8cm)
srand(1234)
```

```@example 1
plot(x=rand(Normal(), 100), y=rand(Normal(), 100), Stat.qq, Geom.point)
plot(x=rand(Normal(), 100), y=Normal(), Stat.qq, Geom.point)
```
