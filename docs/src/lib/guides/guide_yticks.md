```@meta
Author = "Darwin Darakananda"
```

# Guide.yticks

Formats the tick marks and labels for the y-axis

## Arguments
  * `ticks`: Array of tick locations on the y-axis, `:auto` to automatically
    select ticks, or `nothing` to supress y-axis ticks.
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
ticks = [0.2, 0.4, 0.6]
plot(x=rand(10), y=rand(10), Geom.line, Guide.yticks(ticks=ticks))
```

```@example 1
plot(x=rand(10), y=rand(10), Geom.line, Guide.yticks(ticks=ticks, label=false))
```

```@example 1
plot(x=rand(10), y=rand(10), Geom.line, Guide.yticks(ticks=ticks, orientation=:vertical))
```

Range types can also be used

```@example 1
plot(x=rand(1:10, 10), y=rand(1:10, 10), Geom.line, Guide.yticks(ticks=[1:9;]))
```

!!! note

    The `;` in `ticks=[1:9;]` is required to flatten the `1:9` range type into
    `[1, 2, 3, ...]`. Alternatively, `collect` can be used in the following
    manner `ticks=collect(1:9)`.
