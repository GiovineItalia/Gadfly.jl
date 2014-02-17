---
title: ribbon
author: Daniel Jones
part: Geometry
order: 1014
...

Draw a ribbon bounded above and below by `ymin` and `ymin`, respectively.

# Aesthetics

  * `x`: X-axis position
  * `ymin`: Y-axis lower bound.
  * `ymax`: Y-axis upper bound.
  * `color` (optional): Group categorically by color.

# Examples

```{.julia hide="true" results="none"}
using Gadfly, DataFrames

Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
xs = 0:0.1:20

df_cos = DataFrame(
    x=xs,
    y=cos(xs),
    ymin=cos(xs) .- 0.5,
    ymax=cos(xs) .+ 0.5,
    f="cos"
)

df_sin = DataFrame(
    x=xs,
    y=sin(xs),
    ymin=sin(xs) .- 0.5,
    ymax=sin(xs) .+ 0.5,
    f="sin"
)

df = vcat(df_cos, df_sin)
p = plot(df, x=:x, y=:y, ymin=:ymin, ymax=:ymax, color=:f, Geom.line, Geom.ribbon)
```

