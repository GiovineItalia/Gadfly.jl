```@meta
Author = "Darwin Darakananda"
```

# Geom.contour

Draw contours of a 2D function or a matrix.

## Aesthetics

  * `z`: 2D function or a matrix that represent "heights" relative to
    to the x-y plane.
  * `x` (optional): Vector of X-coordinates.  If `z` is a matrix, then
    the length of `x` must be equal to the number of *rows* in `z`.
  * `y` (optional): Vector of Y-coordinates.  If `z` is a matrix, then
    the length of `y` must be equal to the number of *columns* in `z`.

## Arguments
  * `levels` (optional): Sets the number of contours to draw, defaults
    to 15.  It takes either a vector of contour levels, or a integer
    that specifies the number of contours to draw.

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(z=(x,y) -> x*exp(-(x-round(Int, x))^2-y^2),
     x=linspace(-8,8,150), y=linspace(-2,2,150), Geom.contour)
```

```@example 1
volcano = float(array(dataset("datasets", "volcano")))
plot(z=volcano, Geom.contour)
```

```@example 1
plot(z=volcano, Geom.contour(levels=[110.0, 150.0, 180.0, 190.0]))
```

```@example 1
plot(z=volcano, x=collect(0.0:10:860.0), y=collect(0.0:10:600.0),
     Geom.contour(levels=2))
```
