```@meta
Author = "Daniel C. Jones"
```

# Geom.beeswarm

Plot points, shifting them on the x- or y-axis to avoid overlaps.

## Arguments
  * `orientation`: `:horizontal` or `:vertical`.  Points will be shifted on the
    y-axis to avoid overlap if orientation in horizontal, and on the x-axis, if
    vertical.
  * `padding`: Minimum distance between two points.

## Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `color` (optional): Point color (categorial or continuous).


## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
# Binding categorial data to x
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.beeswarm)
```
