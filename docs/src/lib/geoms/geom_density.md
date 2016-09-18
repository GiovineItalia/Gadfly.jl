```@meta
Author = "Daniel C. Jones, Tamas Nagy"
```

# Geom.density

Draw a kernel density estimate from data. An alias for [Geom.line](@ref) with
[Stat.density](@ref).

## Aesthetics

  * `x`: Sample to draw density estimate from.

## Arguments

  * `bandwidth`: How closely the density estimate should mirror the data.
    Larger values will smooth the density estimate out.

## Examples

```@setup 1
using RDatasets
using Gadfly
using Distributions
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.density)
```

```@example 1
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
```

```@example 1
# adjusting bandwidth manually
dist = MixtureModel(Normal, [(0.5, 0.2), (1, 0.1)])
xs = rand(dist, 10^5)
plot(layer(x=xs, Geom.density, Theme(default_color=colorant"orange")), 
layer(x=xs, Geom.density(bandwidth=0.0003), Theme(default_color=colorant"green")),
layer(x=xs, Geom.density(bandwidth=0.25), Theme(default_color=colorant"purple")),
Guide.manual_color_key("bandwidth", ["auto", "bw=0.0003", "bw=0.25"], ["orange", "green", "purple"]))
```
