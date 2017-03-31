```@meta
Author = "Ben J. Arthur"
```

# Geom.abline

For each number in `yintercept`, draw the lines `y = xslope * x +
yintercept` across the plot canvas.  Similarly, for each number in
`xintercept`, draw the lines `x = yslope * y + xintercept` across the
plot canvas.

## Aesthetics

  * `yintercept`: Y-axis intercepts
  * `xslope`: rise over run, defaults to 0
  * `xintercept`: X-axis intercepts
  * `yslope`: run over rise, defaults to 0

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
    yintercept=[0], xslope=[1], Geom.abline(color="red", style=:dash),
    Guide.annotation(compose(context(), text(6,4, "y=x", hleft, vtop), fill(colorant"red"))))
```
