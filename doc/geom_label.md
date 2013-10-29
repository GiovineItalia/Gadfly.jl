---
title: Geom.label
author: Daniel Jones
part: Geometry
order: 8
...

Label positions on the plot frame.

This geometry attemps to optimize label positioning so that labels do not
overlap, and hides any that would overlap.

# Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `label`: Text to render.

# Arguments

```{.julia execute="fales"}
Geom.label(;hide_overlaps=true)
```

  * `hide_overlaps`: If true, labels that would otherwise overlap another
    label or be drawn outside the plot panel are hidden. (default: true)


# Examples


```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 10cm)
```


```julia
plot(data("ggplot2", "mpg"), x="cty", y="hwy", label="model", Geom.point, Geom.label)
```


```julia
plot(data("MASS", "mammals"), x="body", y="brain", label=1,
     Scale.x_log10, Scale.y_log10, Geom.point, Geom.label)
```


