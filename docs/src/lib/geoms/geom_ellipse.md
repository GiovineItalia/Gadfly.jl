```@meta
Author = "Mattriks"
```

# Geom.ellipse

Confidence ellipse for a scatter or group of points, using a parametric multivariate distribution e.g. multivariate normal. `Geom.ellipse` is an instance of [`Geom.polygon`](@ref)

## Aesthetics

  * `x`: Position of points.
  * `y`: Position of points.
  * `color` (optional): Color.
  * `group` (optional): Group.

## Arguments

  * `distribution`: A multivariate distribution. Default is `MvNormal`.
  * `levels`: The quantiles for which confidence ellipses are calculated. Default is [0.95].
  * `nsegments`: Number of segments to draw each ellipse. Default is 51.


## Examples

```@setup 1
using RDatasets, Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
D = dataset("datasets","faithful")
D[:g] = D[:Eruptions].>3.0

coord = Coord.cartesian(ymin=35, ymax=100)

pa = plot(D, coord,
    x=:Eruptions, y=:Waiting, group=:g,
    Geom.point, Geom.ellipse
)
pb = plot(D, coord,
    x=:Eruptions, y=:Waiting, color=:g,
    Geom.point, Geom.ellipse,
    layer(Geom.ellipse(levels=[0.99]), style(line_style=:dot)),
    style(key_position=:none), Guide.ylabel(nothing)
)
hstack(pa,pb)
```
