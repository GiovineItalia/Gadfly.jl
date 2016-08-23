# Geom.rectbin

Draw colored rectangles.

## Aesthetics
  * color

Either

  * x_min
  * x_max
  * y_min
  * y_max

Or

  * x
  * y

In the former case, rectangles defined by `x_min`, `x_max`, `y_min`, `y_max`
are drawn, in the latter, equal sizes squares are centered at `x` and `y`
positions.

## Examples

```@example 1
using RDatasets # hide
using Gadfly # hide
Gadfly.set_default_plot_size(14cm, 8cm) # hide
```

```@example 1
plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP", Geom.rectbin)
```
