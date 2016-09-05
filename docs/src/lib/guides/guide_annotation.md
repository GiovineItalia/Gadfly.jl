```@meta
Author = "Daniel C. Jones"
```

# Guide.annotation

Overlay a plot with an arbitrary [Compose](http://composejl.org/) graphic. The
context will inherit the plot's coordinate system, unless overridden with a
custom unit box.

## Arguments
  * `ctx`: A Compose Context.

## Examples

```@setup 1
using Compose
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(sin, 0, 2pi,
     Guide.annotation(
       compose(context(), circle([pi/2, 3*pi/2], [1.0, -1.0], [2mm]), fill(nothing),
       stroke(colorant"orange"))))

```
