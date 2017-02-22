```@meta
Author = "Ben J. Arthur"
```

# Geom.density2d

Draw a kernel density estimate from data. An alias for [Geom.Contour](@ref) with
[Stat.density2d](@ref).

## Aesthetics

  * `x`, `y`: Sample to draw density estimate from.

## Arguments

  * `bandwidth`:  See [Geom.Density](@ref).

  * `levels`:  See [Geom.Contour](@ref).

## Examples

```@setup 1
using Gadfly
using Distributions
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(x=rand(Rayleigh(2),1000), y=rand(Rayleigh(2),1000),
    Geom.density2d(levels = x->maximum(x)*0.5.^collect(1:2:8)), Geom.point,
    Theme(key_position=:none),
    Scale.color_continuous(colormap=x->colorant"red"))
