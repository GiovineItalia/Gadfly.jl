---
title: Geom.point
author: Daniel Jones
part: Geometry
order: 2
...

The point geometry is used to draw various types of scatterplots.

# Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `color` (optional): Point color (categorial or continuous).

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(data("datasets", "iris"), x="Sepal.Length", y="Sepal.Width", Geom.point)
```

```julia
# Binding categorial data to the color aesthetic
plot(data("datasets", "iris"), x="Sepal.Length", y="Sepal.Width",
     color="Species", Geom.point)
```

```julia
# Binding continuous data to the color aesthetic
plot(data("datasets", "iris"), x="Sepal.Length", y="Sepal.Width",
     color="Petal.Length", Geom.point)
```

```julia
# Binding categorial data to x
plot(data("lattice", "singer"), x="voice.part", y="height", Geom.point)
```

<!-- TODO: shape aesthetic -->

<!-- TODO: size aesthetic -->

