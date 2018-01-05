```@meta
Author = "Mattriks"
```

# Geom.vectorfield

Draw a vectorfield of a 2D function or a matrix. A vectorfield consists of gradient vectors calculated for particular points in a space.

## Aesthetics

  * `z`: 2D function or a matrix that represent "heights" relative to
    to the x-y plane.
  * `x` (optional): Vector of X-coordinates.  If `z` is a matrix, then
    the length of `x` must be equal to the number of *rows* in `z`.
  * `y` (optional): Vector of Y-coordinates.  If `z` is a matrix, then
    the length of `y` must be equal to the number of *columns* in `z`.

## Arguments
  * `smoothness` (optional): Sets the smoothness of the vectorfield,
    defaults to 1.0. Smaller values (→0) result in more local smoothing.
    Larger values (→∞) will approach a plane of best fit.
  * `scale` (optional): Sets the size of vectors, defaults to 1.0. 
  * `samples` (optional): Sets the size of the grid at which to estimate vectors,
    defaults to 20 (i.e. grid is 20 x 20). See the first example below.

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
coord = Coord.cartesian(xmin=-2, xmax=2, ymin=-2, ymax=2)
plot(coord, z=(x,y)->x*exp(-(x^2+y^2)), 
        xmin=[-2], xmax=[2], ymin=[-2], ymax=[2], 
# or:     x=-2:0.25:2.0, y=-2:0.25:2.0,     
        Geom.vectorfield(scale=0.4, samples=17), Geom.contour(levels=6),
        Scale.x_continuous(minvalue=-2.0, maxvalue=2.0),
        Scale.y_continuous(minvalue=-2.0, maxvalue=2.0),
        Guide.xlabel("x"), Guide.ylabel("y"), Guide.colorkey(title="z")
    )
```

```@example 1
volcano = Matrix{Float64}(dataset("datasets", "volcano"))
volc = volcano[1:4:end, 1:4:end] 
coord = Coord.cartesian(xmin=1, xmax=22, ymin=1, ymax=16)
plot(coord, z=volc, x=1.0:22, y=1.0:16,
        Geom.vectorfield(scale=0.05), Geom.contour(levels=7),
        Scale.x_continuous(minvalue=1.0, maxvalue=22.0),
        Scale.y_continuous(minvalue=1.0, maxvalue=16.0),
        Guide.xlabel("x"), Guide.ylabel("y"),
        Theme(key_position=:none)
    )
```

