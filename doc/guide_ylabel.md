---
title: ylabel
author: Darwin Darakananda
part: Guide
order: 3001
...

Sets the y-axis label for the plot.

# Arguments
  * `label`: Y-axis label
  * `orientation` (optional): `:horizontal`, `:vertical`, or `:auto` (default)

`label` is not a keyword parameter, it must be supplied as the first
argument of `Guide.ylabel`.  Setting it to `nothing` will suppress
the default label.

# Examples

```{.julia hide="true" results="none"}
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(cos, 0, 2π, Guide.ylabel("cos(x)"))
```

```julia
plot(cos, 0, 2π, Guide.ylabel("cos(x)", orientation=:horizontal))
```

```julia
plot(cos, 0, 2π, Guide.ylabel(nothing))
```
