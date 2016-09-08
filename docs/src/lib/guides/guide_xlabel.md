```@meta
Author = "Darwin Darakananda"
```

# Guide.xlabel

Sets the x-axis label for the plot.

## Arguments
  * `label`: X-axis label
  * `orientation` (optional): `:horizontal`, `:vertical`, or `:auto` (default)

`label` is not a keyword parameter, it must be supplied as the first
argument of [Guide.xlabel](@ref).  Setting it to `nothing` will suppress
the default label.

## Examples

```@setup 1
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(cos, 0, 2π, Guide.xlabel("Angle"))
```

```@example 1
plot(cos, 0, 2π, Guide.xlabel("Angle", orientation=:vertical))
```

```@example 1
plot(cos, 0, 2π, Guide.xlabel(nothing))
```
