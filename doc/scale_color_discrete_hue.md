---
title: color_discrete_hue
author: David Chudzicki
part: Scale
order: 2008
...

Create a discrete color scale to be used for the plot.

# Arguments

  * `levels` (optional): Explicitly set levels used by the scale. Order is
    respected.
  * `order` (optional): A vector of integers giving a permutation of the levels
    default order.

# Variations 

```discrete_color``` and ```discrete_color_hue``` are names for the same thing.

# Examples

```{.julia hide="true" results="none"}
using Gadfly

srand(1234)
```

This forces the use of a discrete scale on data that would otherwise receive a continuous scale:

```julia
plot(x=rand(12), y=rand(12), color=repeat([1,2,3], outer=[4]),
     Scale.color_discrete())
```
