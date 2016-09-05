---
title: yticks
author: Darwin Darakananda
part: Guide
order: 3003
...

Formats the tick marks and labels for the y-axis

# Arguments
  * `ticks`: Array of tick locations on the y-axis, `:auto` to automatically
    select ticks, or `nothing` to supress y-axis ticks.  Note that any ticks 
    set here will be overwritten by any set in `Stat.yticks`.
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
ticks = [0.2, 0.4, 0.6]
plot(x=rand(10), y=rand(10), Geom.line, Guide.yticks(ticks=ticks))
```

```julia
plot(x=rand(10), y=rand(10), Geom.line, Guide.yticks(ticks=ticks, label=false))
```

```julia
plot(x=rand(10), y=rand(10), Geom.line, Guide.yticks(ticks=ticks, orientation=:vertical))
```

