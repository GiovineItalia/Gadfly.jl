---
title: density
author: Daniel Jones
part: Geometry
order: 1001
...

Draw a kernel density estimate from data. An alias for `Geom.line` with
`Stat.density`.

# Aesthetics

  * `x`: Sample to draw density estimate from.

# Arguments

  * bandwidth: How closely the density estimate should mirror the data.
    Larger values will smooth the density estimate out.

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly
using Distributions

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.density)
```

```julia
plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
```

```julia
# adjusting bandwidth manually
dist = MixtureModel(Normal, [(0.5, 0.2), (1, 0.1)])
xs = rand(dist, 10^5)
plot(layer(x=xs, Geom.density, Theme(default_color=colorant"orange")), 
layer(x=xs, Geom.density(bandwidth=0.003), Theme(default_color=colorant"blue")),
layer(x=xs, Geom.density(bandwidth=0.25), Theme(default_color=colorant"purple")),
Guide.manual_color_key("bandwidth", ["auto", "bw=0.003", "bw=0.25"], ["orange", "blue", "purple"]))
```
