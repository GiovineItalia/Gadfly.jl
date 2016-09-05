```@meta
Author = "Daniel C. Jones"
```

# Guide.colorkey

Set the title for the plot legend

## Arguments
  * `title`: Legend title

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
volcano = float(convert(Array, dataset("datasets", "volcano")))
plot(z=volcano, Geom.contour, Guide.colorkey("Elevation"))
```
