---
title: colorkey
author: Darwin Darakananda
part: Guide
order: 3005
...

Set the title for the plot legend

# Arguments
  * `title`: Legend title

# Examples

```{.julia hide="true" results="none"}
using Gadfly
using RDatasets

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
volcano = float(array(dataset("datasets", "volcano")))
plot(z=volcano, Geom.contour, Guide.colorkey("Elevation"))
```
