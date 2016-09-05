```@meta
Author = "Daniel C. Jones"
```

# Geom.label

Label positions on the plot frame.

This geometry attemps to optimize label positioning so that labels do not
overlap, and hides any that would overlap.

## Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `label`: Text to render.

## Arguments

  * `position`: One of `:dynamic`, `:left`, `:right`, `:above`, `:below`,
    `:centered`. If `:dynamic` is used, label positions will be adjusted to
    avoid overaps. Otherwise, labels will be statically positioned left, right,
    above, below, or centered relative to the point.

  * `hide_overlaps`: If true, and dynamic positioning is used, labels that would
    otherwise overlap another label or be drawn outside the plot panel are
    hidden. (default: true)


## Examples


```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 10cm)
```


```@example 1
plot(dataset("ggplot2", "mpg"), x="Cty", y="Hwy", label="Model", Geom.point, Geom.label)
```


```@example 1
plot(dataset("MASS", "mammals"), x="Body", y="Brain", label=1,
     Scale.x_log10, Scale.y_log10, Geom.point, Geom.label)
```

```@example 1
plot(dataset("MASS", "mammals"), x="Body", y="Brain", label=1,
     Scale.x_log10, Scale.y_log10, Geom.label(position=:centered))
```
