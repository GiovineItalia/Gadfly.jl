```@meta
Author = "Darwin Darakananda and Mattriks"
```

# Geom.contour

Draw contours of a 2D function, matrix or `DataFrame`. Note that `Geom.contour` currently works for gridded points, not irregular points.

## Aesthetics

  * `z`: 2D function or a matrix that represent "heights" relative to the x-y plane.    
  * `x` (optional): Vector of X-coordinates.  If `z` is a matrix, then
    the length of `x` must be equal to the number of *rows* in `z`.
  * `y` (optional): Vector of Y-coordinates.  If `z` is a matrix, then
    the length of `y` must be equal to the number of *columns* in `z`.

Alternatively, you can supply a `DataFrame` containing `x`, `y`, `z` values (the names in the dataframe don't need to be `x`, `y`, `z`). See the last example below. Note that `Geom.subplot_grid` plus `Geom.contour` works with a `DataFrame`.

## Arguments
  * `levels` (optional): Sets the number of contours to draw, defaults
    to 15.  It takes either a vector of contour levels;  an integer
    that specifies the number of contours to draw;  or a function which
    inputs `z` and outputs either a vector or an integer.

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
volcano = Matrix{Float64}(dataset("datasets", "volcano"))
plot(z=volcano, Geom.contour)
```

```@example 1
plot(z=volcano, Geom.contour(levels=[110.0, 150.0, 180.0, 190.0]))
```

```@example 1
plot(z=volcano, x=collect(0.0:10:860.0), y=collect(0.0:10:600.0),
     Geom.contour(levels=2))
```

```@example 1
Mvolc = volcano[1:4:end, 1:4:end]
Dvolc = vcat([DataFrame(x=[1:size(Mvolc,1);], y=j, z=Mvolc[:,j]) for j in 1:size(Mvolc,2)]...)

coord = Coord.cartesian(xmin=1, xmax=22, ymin=1, ymax=16)
plot(Dvolc, x=:x, y=:y, z=:z, color=:z, coord,
    Geom.point, Geom.contour(levels=10), style(line_width=0.5mm, point_size=0.2mm) )
```

