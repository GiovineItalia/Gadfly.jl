---
title: color_continuous_gradient
author: David Chudzicki
part: Scale
order: 2008
...

Create a continuous color scale that the plot will use.

# Arguments

  * `minvalue` (optional): the data value corresponding to the bottom of the color scale (will be based on the range of the data if not specified).
  * `maxvalue` (optional): the data value corresponding to the bottom of the color scale (will be based on the range of the data if not specified).

# Variations

```continuous_color``` and ```continuous_color_gradient``` are two names for the same thing.

# Aesthetics Acted On

`color`

# Examples

```{.julia hide="true" results="none"}
using Gadfly

srand(1234)
```

```julia
# The data are all between 0 and 1, but the color scale goes from -1 to 1. 
# For example, you might do this to force a consistent color scale between plots.
plot(x=rand(12), y=rand(12), color=rand(12), 
     Scale.color_continuous(minvalue=-1, maxvalue=1))
```
