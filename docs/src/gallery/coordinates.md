# Coordinates

## [`Coord.cartesian`](@ref)

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(sin, 0, 20, Coord.cartesian(xmin=2π, xmax=4π, ymin=-2, ymax=2))
```
