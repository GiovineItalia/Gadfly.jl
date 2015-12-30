---
title: color_continuous
author: David Chudzicki
part: Scale
order: 2008
...

Create a continuous color scale that the plot will use.

# Arguments

  * `minvalue` (optional): the data value corresponding to the bottom of the color scale (will be based on the range of the data if not specified).
  * `maxvalue` (optional): the data value corresponding to the top of the color scale (will be based on the range of the data if not specified).
  * `colormap`: A function defined on the interval from 0 to 1 that returns a ```Color``` (as from the ```Colors``` package).

# Variations

```color_continuous``` and ```color_continuous_gradient``` are two names for the same thing.

A number of transformed continuous scales are provided.

  * `Scale.color_continuous` (scale without any transformation).
  * `Scale.color_log10`
  * `Scale.color_log2`
  * `Scale.color_log`
  * `Scale.color_asinh`
  * `Scale.color_sqrt`

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

Define a custom color scale for a grid:

```julia
using Colors
x = repeat(collect(1:10), inner=[10])
y = repeat(collect(1:10), outer=[10])
plot(x=x, y=y, color=x+y, Geom.rectbin,
     Scale.color_continuous(colormap=p->RGB(0,p,0)))
```

Or we can use ```lab_gradient``` to construct a color gradient between 2 or more colors:

```julia
plot(x=x, y=y, color=x+y, Geom.rectbin,
     Scale.color_continuous(colormap=Scale.lab_gradient(colorant"green",
                                                        colorant"white",
                                                        colorant"red")))
```

We can also start the color scale somewhere other than the bottom of the data range using ```minvalue```:

```julia
plot(x=x, y=y, color=x+y, Geom.rectbin,
     Scale.color_continuous(colormap=p->RGB(0,p,0), minvalue=-20))
```
