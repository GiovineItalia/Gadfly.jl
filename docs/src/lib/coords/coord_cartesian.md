```@meta
Author = "Daniel C. Jones"
```

# Coord.cartesian

## Arguments
  * `xmin`: Hard minimum value on the x-axis.
  * `xmax`: hard maximum value on the x-axis.
  * `ymin`: Hard minimum value on the y-axis.
  * `ymax`: Hard maximum value on the y-axis.
  * `xflip`: True if the x-axis should be flipped. (default: `false`)
  * `yflip`: True if the y-axis should be flipped. (default: `false`)
  * `aspect_ratio`: Aspect ratio, or `nothing` if no fixed aspect ratio. (default: nothing)
  * `fixed`: True if the ratio should follow the units of the plot. E.g. if the
    y-axis is 5 units high and the x-axis in 10 units across, the plot will be
    drawn at an aspect ratio of 2. Overrides `aspect_ratio` (default: false)

## Examples

```@setup 1
using Gadfly
```

```@example 1
# Transform both dimensions
plot(sin, 0, 20, Coord.cartesian(xmin=2π, xmax=4π, ymin=-2, ymax=2))
```
