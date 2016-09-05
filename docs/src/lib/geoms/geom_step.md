```@meta
Author = "Daniel C. Jones"
```

# Geom.step

Connect points using a stepwise function. Equivalent to [Geom.line](@ref) with
[Stat.step](@ref).

## Aesthetics

  * `x`: Point x-coordinate.
  * `y`: Point y-coordinate.

## Arguments

  * `direction`: Either `:hv` for horizontal then vertical, or `:vh` for
    vertical then horizontal.

## Examples

```@setup 1
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
srand(1234)
```

```@example 1
plot(x=rand(25), y=rand(25), Geom.step)
```
