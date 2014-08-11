---
title: hexbin
author: Daniel Jones
part: Geometry
order: 1013
...

Bin data into tiled hexagonal bins and color by count.

# Aesthetics
  * `x`: Observations to be binned and plotted on the x-axis.
  * `y`: Observations to be binned and plotted on the y-axis.
  * `xsize`
  * `ysize`

By default `Stat.hexbin` is applied which bins `x` and `y` observations and
colors hexagons according to count. To override this, pass `Stat.identity` to
`plot` and manually bind the `color` aesthetic.

# Arguments

  * `xbincount`: Number of bins along the x-axis.
  * `ybincount`: Number of bins along the y-axis.

# Examples

```{.julia hide="true" results="none"}
using Gadfly, Distributions

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
X = rand(MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0]), 10000)
```

```julia
plot(x=X[1,:], y=X[2,:], Geom.hexbin)
```

```julia
plot(x=X[1,:], y=X[2,:], Geom.hexbin(xbincount=100, ybincount=100))
```
