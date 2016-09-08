```@meta
Author = "Daniel C. Jones"
```

# Geom.hline

Draw horizontal lines across the plot canvas.

## Aesthetics

  * `yintercept`: Y-axis intercept

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
	 yintercept=[2.5, 4.0], Geom.point, Geom.hline)
```

```@example 1
# Colors and widths of lines can be changed. This works separately from the
# `color` and `size` aesthetics.
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
	 yintercept=[2.5, 4.0], Geom.point,
	 Geom.hline(color=colorant"orange", size=2mm))
```
