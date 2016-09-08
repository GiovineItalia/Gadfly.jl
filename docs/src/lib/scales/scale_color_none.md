```@meta
Author = "Daniel C. Jones"
```

# Scale.color_none

Suppress a default color scale. Some statistics impose a default color scale.
When no color scale is desired, explicitly including [Scale.color_none](@ref) will
suppress this default.

## Examples

```@setup 1
using Gadfly
srand(1234)
```

```@example 1
xs = 1:10.
ys = 1:10.
zs = Float64[x^2*log(y) for x in xs, y in ys]
plot(x=xs, y=ys, z=zs, Geom.contour, Scale.color_none)
```
