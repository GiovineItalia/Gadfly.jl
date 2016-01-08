---
title: errorbar
author: Daniel Jones
part: Geometry
order: 1002
...

Draw vertical and/or horizontal error bars.

# Aesthetics

  * `x`: X-position of the bar.
  * `ymin`: Lower Y-position.
  * `ymax`: Upper Y-position.
  * `y`: Y-position of the bar.
  * `xmin`: Lef-tmost X-position
  * `ymax`: Right-most X-position.
  * `color` (optional): Bar color (categorial or continuous)

The `x`, `ymin`, `ymax` and/or `y`, `xmin`, `xmax` aesthetics must be defined.
With the later a vertical error bar is drawn, and the former, a horizontal bar.

# Examples


```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
srand(1234)
```

```julia
using Distributions

sds = [1, 1/2, 1/4, 1/8, 1/16, 1/32]
n = 10
ys = [mean(rand(Normal(0, sd), n)) for sd in sds]
ymins = ys .- (1.96 * sds / sqrt(n))
ymaxs = ys .+ (1.96 * sds / sqrt(n))

plot(x=1:length(sds), y=ys, ymin=ymins, ymax=ymaxs,
     Geom.point, Geom.errorbar)
```


