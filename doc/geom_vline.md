---
title: vline
author: Daniel Jones
part: Geometry
order: 1012
...

Draw vertical lines across the plot canvas.

# Aesthetics

  * `xintercept`: X-axis intercept

# Arguments

  * `color`: Color of the lines.
  * `size`: Width of the lines.

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
	 xintercept=[5.0, 7.0], Geom.point, Geom.vline)
```

```julia
# Colors and widths of lines can be changed. This works separately from the
# `color` and `size` aesthetics.
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
	 xintercept=[5.0, 7.0], Geom.point,
	 Geom.vline(color="orange", size=2mm))
```

