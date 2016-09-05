```@meta
Author = "Daniel C. Jones"
```

# Geom.hexbin

Bin data into tiled hexagonal bins and color by count.

## Aesthetics
  * `x`: Observations to be binned and plotted on the x-axis.
  * `y`: Observations to be binned and plotted on the y-axis.
  * `xsize`
  * `ysize`

By default [Stat.hexbin](@ref) is applied which bins `x` and `y` observations and
colors hexagons according to count. To override this, pass [Stat.identity](@ref) to
`plot` and manually bind the `color` aesthetic.

## Arguments

  * `xbincount`: Number of bins along the x-axis.
  * `ybincount`: Number of bins along the y-axis.

## Examples

```@setup 1
using Gadfly, Distributions
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
X = rand(MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0]), 10000);
plot(x=X[1,:], y=X[2,:], Geom.hexbin)
```

```@example 1
plot(x=X[1,:], y=X[2,:], Geom.hexbin(xbincount=100, ybincount=100))
```
