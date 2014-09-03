---
title: x_continuous
author: Daniel Jones
part: Scale
order: 2000
...

Map numerical data to x positions in cartesian coordinates.

# Arguments

  * `minvalue`: Force the plot viewport to a minimum x value.
  * `maxvalue`: Force the plot viewport to a maximum x value.
  * `format`: How numbers should be formatted. One of `:plain`, `:scientific`,
    `:engineering`, or `:auto`. The default in `:auto` which prints very large or very small
    numbers in scientific notation, and other numbers plainly.
  * `scalable`: When set to false, scale is fixed when zooming (default: true)

# Variations

A number of transformed continuous scales are provided.

  * `Scale.x_continuous` (scale without any transformation).
  * `Scale.x_log10`
  * `Scale.x_log2`
  * `Scale.x_log`
  * `Scale.x_asinh`
  * `Scale.x_sqrt`


# Aesthetics Acted On

`x`, `xmin`, `xmax`, `xintercept`

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

srand(1234)
```

```julia
# Transform both dimensions
plot(x=rand(10), y=rand(10), Scale.x_log)
```

```julia
# Force the viewport
plot(x=rand(10), y=rand(10), Scale.x_continuous(minvalue=-10, maxvalue=10))
```


```julia
# Use scientific notation
plot(x=rand(10), y=rand(10), Scale.x_continuous(format=:scientific))
```

