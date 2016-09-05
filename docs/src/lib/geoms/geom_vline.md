```@meta
Author = "Daniel C. Jones"
```

# Geom.vline

Draw vertical lines across the plot canvas.

## Aesthetics

  * `xintercept`: X-axis intercept

## Arguments

  * `color`: Color of the lines.
  * `size`: Width of the lines.

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
	 xintercept=[5.0, 7.0], Geom.point, Geom.vline)
```

```@example 1
# Colors and widths of lines can be changed. This works separately from the
# `color` and `size` aesthetics.
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
	 xintercept=[5.0, 7.0], Geom.point,
	 Geom.vline(color=colorant"orange", size=2mm))
```
