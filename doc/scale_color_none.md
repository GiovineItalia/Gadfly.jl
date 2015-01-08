---
title: color_none
author: Daniel C. Jones
part: Scale
order: 2009
...

Supress a default color scale. Some statistics impose a default color scale.
When no color scale is desider, explicitly including `Scale.color_none` will
supress this default.

# Examples

```{.julia hide="true" results="none"}
using Gadfly
```

```julia
xs = 1:10.
ys = 1:10.
zs = Float64[x^2*log(y) for x in xs, y in ys]
plot(x=xs, y=ys, z=zs, Geom.contour, Scale.color_none)
```

