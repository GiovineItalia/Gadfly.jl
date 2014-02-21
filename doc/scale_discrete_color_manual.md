---
title: discrete_color_manual
author: David Chudzicki
part: Scale
order: 2008
...

Create a discrete color scale to be used for the plot.

# Arguments

  * `colors...`: an iterable collection of things that can be converted to colors with ```Color.color``` (such as strings naming colors)
  * `levels` (optional): Explicitly set levels used by the scale. Order is
    respected.
  * `order` (optional): A vector of integers giving a permutation of the levels
    default order.

# Aesthetics Acted On

`color`

# Examples

```{.julia hide="true" results="none"}
using Gadfly

Gadfly.prepare_display()
srand(1234)
```

```julia
plot(x=rand(12), y=rand(12), color=repeat(["a","b","c"], outer=[4]), 
     Scale.discrete_color_manual("red","purple","green"))
```
