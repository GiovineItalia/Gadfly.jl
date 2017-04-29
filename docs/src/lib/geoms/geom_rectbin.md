```@meta
Author = "Daniel C. Jones, Mattriks"
```

# Geom.rectbin

Draw colored rectangles.

## Aesthetics
  * color

Either (for `Geom.rect`)

  * x_min
  * x_max
  * y_min
  * y_max

Or (for `Geom.rectbin`)

  * x
  * y

For `Geom.rect`, rectangles defined by `x_min`, `x_max`, `y_min`, `y_max`
are drawn.  
For `Geom.rectbin`, equal sizes squares are centered at `x` and `y`
positions.

## Examples

```@setup 1
using DataFrames, RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP", Geom.rectbin)
```

```@example 1
theme1 = Theme(default_color=RGBA(0, 0.75, 1.0, 0.5))
D = DataFrame(x=[0.5,1], y=[0.5,1], x1=[0,0.5], y1=[0,0.5], x2=[1,1.5], y2=[1,1.5])
pa = plot(D, x=:x, y=:y, Geom.rectbin, theme1)
pb = plot(D, xmin=:x1, ymin=:y1, xmax=:x2, ymax=:y2, Geom.rect, theme1)
hstack(pa, pb)
```
