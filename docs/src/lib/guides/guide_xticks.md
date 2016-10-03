```@meta
Author = "Darwin Darakananda"
```

# Guide.xticks

Formats the tick marks and labels for the x-axis

## Arguments
  * `ticks`: Array of tick locations on the x-axis, `:auto` to automatically
    select ticks, or `nothing` to supress x-axis ticks.
  * `label`: Determines if the ticks are labeled, either
    `true` (default) or `false`
  * `orientation`: Label orientation
    (`:horizontal, :vertical, :auto`). Defaults to `:auto`

## Examples

```@setup 1
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
ticks = [0.1, 0.3, 0.5]
plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks))
```

```@example 1
plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks, label=false))
```

```@example 1
plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks, orientation=:vertical))
```

Range types can also be used

```@example 1
plot(x=rand(1:10, 10), y=rand(1:10, 10), Geom.line, Guide.xticks(ticks=[1:9;]))
```

!!! note

    The `;` in `ticks=[1:9;]` is required to flatten the `1:9` range type into
    `[1, 2, 3, ...]`. Alternatively, `collect` can be used in the following
    manner `ticks=collect(1:9)`.
