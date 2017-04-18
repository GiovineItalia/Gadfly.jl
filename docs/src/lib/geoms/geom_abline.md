```@meta
Author = "Ben J. Arthur"
```

# Geom.abline

For each corresponding pair of elements in `intercept` and `slope`, draw the
lines `y = slope * x + intercept` across the plot canvas.

Currently does not support non-linear `Scale` transformations.

## Aesthetics

  * `intercept`: Y-axis intercepts, defaults to [0]
  * `slope`: rise over run, defaults to [1]

## Arguments

  * `color`: Color of the lines.
  * `size`: Width of the lines.
  * `style`: Style of the lines.

## Examples

```@setup 1
using Gadfly, RDatasets, Compose
Gadfly.set_default_plot_size(14cm, 10cm)
```

```@example 1
plot(dataset("ggplot2", "mpg"), x="Cty", y="Hwy", label="Model", Geom.point, Geom.label,
    intercept=[0], slope=[1], Geom.abline(color="red", style=:dash),
    Guide.annotation(compose(context(), text(6,4, "y=x", hleft, vtop), fill(colorant"red"))))
```
