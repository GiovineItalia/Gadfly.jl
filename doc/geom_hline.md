---
title: hline
author: Daniel Jones
part: Geometry
order: 1005
...

Draw horizontal lines across the plot canvas.

# Aesthetics

  * `yintercept`: Y-axis intercept

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
plot(data("datasets", "iris"), x="Sepal.Length", y="Sepal.Width",
	 yintercept=[2.5, 4.0], Geom.point, Geom.hline)
```

```julia
# Colors and widths of lines can be changed. This works separately from the
# `color` and `size` aesthetics.
plot(data("datasets", "iris"), x="Sepal.Length", y="Sepal.Width",
	 yintercept=[2.5, 4.0], Geom.point,
	 Geom.hline(color="orange", size=2mm))
```

