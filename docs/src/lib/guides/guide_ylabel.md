```@meta
Author = "Darwin Darakananda"
```

# Guide.ylabel

Sets the y-axis label for the plot.

## Arguments
  * `label`: Y-axis label
  * `orientation` (optional): `:horizontal`, `:vertical`, or `:auto` (default)

`label` is not a keyword parameter, it must be supplied as the first
argument of `Guide.ylabel`.  Setting it to `nothing` will suppress
the default label.

## Examples

```@setup 1
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```


```@example 1
plot(cos, 0, 2π, Guide.ylabel("cos(x)"))
```

```@example 1
plot(cos, 0, 2π, Guide.ylabel("cos(x)", orientation=:horizontal))
```

```@example 1
plot(cos, 0, 2π, Guide.ylabel(nothing))
```
