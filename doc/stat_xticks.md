---
title: xticks
author: Daniel C. Jones
part: Statistic
order: 1002
...

Compute an appealing set of ticks that encompass the data or specify a set of ticks to use.

# Arguments

  * `granularity_weight`: Importance of having a reasonable number of ticks. (Default: `1/4`)
  * `simplicity_weight`: Importance of including zero. (Default: `1/6`)
  * `coverage_weight`: Importance of tightly fitting the span of the data. (Default: `1/3`)
  * `niceness_weight`: Importance of having a nice numbering. (Default: `1/4`)

or

  * `ticks`: A fixed array of ticks to use.  This overwrites any ticks set in `Guide.xticks`.

# Aesthetics

All x-axis aesthetics are considered, and ticks are output to the `xtick` and
`xgrid` aesthetics.

# Examples

```{.julia hide="true" results="none"}
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
# A plot with ticks computed with the default arguments
plot(x=rand(10), y=rand(10), Geom.point)
```

```julia
# Prefer nicely-numbered ticks
plot(x=rand(10), y=rand(10),
     Stat.xticks(niceness_weight=0.5), Geom.point)
```

```julia
# Providing a fixed set of ticks
plot(x=rand(10), y=rand(10),
     Stat.xticks(ticks=[0.0, 0.1, 0.9, 1.0]), Geom.point)
```
