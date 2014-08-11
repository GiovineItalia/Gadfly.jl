---
title: xlabel
author: Darwin Darakananda
part: Guide
order: 3000
...

Sets the x-axis label for the plot.

# Arguments
  * `label`: X-axis label
  * `orientation` (optional): `:horizontal`, `:vertical`, or `:auto` (default)

`label` is not a keyword parameter, it must be supplied as the first
argument of `Guide.xlabel`.  Setting it to `nothing` will suppress
the default label.

# Examples

```{.julia hide="true" results="none"}
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(cos, 0, 2π, Guide.xlabel("Angle"))
```

```julia
plot(cos, 0, 2π, Guide.xlabel("Angle", orientation=:vertical))
```

```julia
plot(cos, 0, 2π, Guide.xlabel(nothing))
```
