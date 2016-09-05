```@meta
Author = "Daniel C. Jones"
```

# Stat.xticks

Compute an appealing set of ticks that encompass the data.

## Arguments

  * `ticks`: A fixed array of ticks, or `nothing` to indicate they should be
    computed.
  * `granularity_weight`: Importance of having a reasonable number of ticks. (Default: `1/4`)
  * `simplicity_weight`: Importance of including zero. (Default: `1/6`)
  * `coverage_weight`: Importance of tightly fitting the span of the data. (Default: `1/3`)
  * `niceness_weight`: Importance of having a nice numbering. (Default: `1/4`)

## Aesthetics

All x-axis aesthetics are considered, and ticks are output to the `xtick` and
`xgrid` aesthetics.

## Examples

```@setup 1
using Gadfly
Gadfly.set_default_plot_size(12cm, 8cm)
srand(1234)
```

```@example 1
# Providing a fixed set of ticks
plot(x=rand(10), y=rand(10),
     Stat.xticks(ticks=[0.0, 0.1, 0.9, 1.0]), Geom.point)
```
