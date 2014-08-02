---
title: point
author: Daniel Jones
part: Geometry
order: 1008
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

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point)
```

```julia
# Binding categorial data to the color aesthetic
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
     color="Species", Geom.point)
```

```julia
# Binding continuous data to the color aesthetic
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
     color="PetalLength", Geom.point)
```

```julia
# Binding categorial data to x
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.point)
```

<!-- TODO: shape aesthetic -->

<!-- TODO: size aesthetic -->

