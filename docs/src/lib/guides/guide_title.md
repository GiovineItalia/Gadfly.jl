```@meta
Author = "Darwin Darakananda"
```

# Guide.title

Set the plot tile

## Arguments
  * `title`: Plot title

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.histogram, Guide.title("Diamond Price Distribution"))
```
