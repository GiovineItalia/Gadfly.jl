---
title: xticks
author: Darwin Darakananda
part: Guide
order: 3002
...

Formats the tick marks and labels for the x-axis

# Arguments
  * `ticks`: Array of tick locations on the x-axis, `:auto` to automatically
    select ticks, or `nothing` to supress x-axis ticks.
  * `label`: Determines if the ticks are labeled, either
    `true` (default) or `false`
  * `orientation`: Label orientation
    (`:horizontal, :vertical, :auto`). Defaults to `:auto`

# Examples

```{.julia hide="true" results="none"}
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
ticks = [0.1, 0.3, 0.5]
plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks))
```

```julia
plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks, label=false))
```

```julia
plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks, orientation=:vertical))
```

