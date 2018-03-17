# Coordinates

## Coord.cartesian

```@example
using Gadfly
# Transform both dimensions
plot(sin, 0, 20, Coord.cartesian(xmin=2π, xmax=4π, ymin=-2, ymax=2))
```
