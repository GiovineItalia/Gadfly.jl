```@meta
Author = "Daniel C. Jones"
```

# Geom.polygon

Draw polygons.

## Aesthetics

Aesthetics used directly:

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `group` (optional): Group categorically.
  * `color` (optional): Group categorically and indicate by color.

## Arguments

  * `order`: Z-order relative to other geometry.
  * `fill`: If true, fill the polygon and stroke according to
    `Theme.discrete_highlight_color`. If false (default), only stroke.
  * `preserve_order`: If true, connect points in the order they are given. If
    false (default) order the points around their centroid.

## Examples


```@setup 1
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(x=[0, 1, 1, 2, 2, 3, 3, 2, 2, 1, 1, 0, 4, 5, 5, 4],
     y=[0, 0, 1, 1, 0, 0, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3],
     group=["H", "H", "H", "H", "H", "H", "H", "H",
            "H", "H", "H", "H", "I", "I", "I", "I"],
     Geom.polygon(preserve_order=true, fill=true))
```
