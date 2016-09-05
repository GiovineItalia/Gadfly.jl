```@meta
Author = "Daniel C. Jones"
```

# Geom.histogram2d

Bin data in rectangles and indicate density with color. As in heatmaps, etc.

An alias for [Geom.rectbin](@ref) with [Stat.histogram2d](@ref).

## Aesthetics

  * `x`: Observations to be binned and plotted on the x coordinate.
  * `y`: Observations to binned and plotted on the y coordinate.

## Arguments

  * `xbincount`: Fix the number of bins in the x coordinate.
  * `xminbincount`: Set the minimum x coordinate bincount when automatically
    determining the number of bins.
  * `xmaxbincount`: Set the maximum x coordinate bincount when automatically
    determining the number of bins.
  * `ybincount`: Fix the number of bins in the y coordinate.
  * `yminbincount`: Set the minimum y coordinate bincount when automatically
    determining the number of bins.
  * `ymaxbincount`: Set the maximum y coordinate bincount when automatically
    determining the number of bin.

## Examples


```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```


```@example 1
plot(dataset("car", "Womenlf"), x="HIncome", y="Region", Geom.histogram2d)
```

```@example 1
plot(dataset("car", "UN"), x="GDP", y="InfantMortality",
     Scale.x_log10, Scale.y_log10, Geom.histogram2d)
```

```@example 1
# Explicitly setting the number of bins
plot(dataset("car", "UN"), x="GDP", y="InfantMortality",
     Scale.x_log10, Scale.y_log10, Geom.histogram2d(xbincount=30, ybincount=30))
```
