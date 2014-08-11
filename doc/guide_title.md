---
title: title
author: Darwin Darakananda
part: Guide
order: 3004
...

Set the plot tile

# Arguments
  * `title`: Plot title

# Examples

```{.julia hide="true" results="none"}
using Gadfly
using RDatasets

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.histogram, Guide.title("Diamond Price Distribution"))
```
