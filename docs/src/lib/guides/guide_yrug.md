# Guide.yrug

Draw a rug plot along the y-axis of a plot.

## Aesthetics
  * `y`: Y positions of notches.

## Examples

```@example 1
using Compose # hide
using Gadfly # hide
Gadfly.set_default_plot_size(14cm, 8cm) # hide
```

```@example 1
plot(x=rand(20), y=rand(20), Guide.yrug)
```
