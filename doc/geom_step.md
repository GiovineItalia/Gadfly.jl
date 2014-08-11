---
title: step
author: Daniel Jones
part: Geometry
order: 1013
...

Connect points using a stepwise function. Equivalent to `Geom.line` with
`Stat.step`.

# Aesthetics

  * `x`: Point x-coordinate.
  * `y`: Point y-coordinate.

# Arguments

  * `direction`: Either `:hv` for horizontal then vertical, or `:vh` for
    vertical then horizontal.

# Examples

```{.julia hide="true" results="none"}
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
srand(1234)
```

```julia
plot(x=rand(25), y=rand(25), Geom.step)
```


