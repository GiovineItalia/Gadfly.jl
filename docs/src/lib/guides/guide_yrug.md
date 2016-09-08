```@meta
Author = "Daniel C. Jones"
```

# Guide.yrug

Draw a rug plot along the y-axis of a plot.

## Aesthetics
  * `y`: Y positions of notches.

## Examples

```@setup 1
using Compose
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(x=rand(20), y=rand(20), Guide.yrug)
```
