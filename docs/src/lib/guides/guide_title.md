# Guide.title

Set the plot tile

## Arguments
  * `title`: Plot title

## Examples

```@example 1
using RDatasets # hide
using Gadfly # hide
Gadfly.set_default_plot_size(14cm, 8cm) # hide
```

```@example 1
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.histogram, Guide.title("Diamond Price Distribution"))
```
