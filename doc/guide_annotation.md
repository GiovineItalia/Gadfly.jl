---
title: annotation
author: Daniel C. Jones
part: Guide
order: 3006
...

Overlay a plot with an arbitrary [compose](http://composejl.org/) graphic. The
context will inherit the plot's coordinate system, unless overridden with a
custom unit box.

# Arguments
  * `ctx`: A Compose Context.

# Examples

```{.julia hide="true" results="none"}
using Gadfly
using Compose

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(sin, 0, 2pi,
     Guide.annotation(
       compose(context(), circle([pi/2, 3*pi/2], [1.0, -1.0], [2mm]), fill(nothing),
       stroke("orange"))))

```

