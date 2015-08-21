---
title: ContinuousColorScale
author: David Chudzicki
part: Scale
order: 2006
...

Create a continuous color scale to be used for the plot.

# Arguments

  * `f`: A function defined on the interval from 0 to 1 that returns a ```:Color``` (as from the ```Colors``` package).
  * `minvalue` (optional): the data value corresponding to the bottom of the color scale (will be based on the range of the data if not specified)
  * `maxvalue` (optional): the data value corresponding to the top of the color scale (will be based on the range of the data if not specified)

# Aesthetics Acted On

`color`

# Examples

```{.julia hide="true" results="none"}
using Gadfly

```

Define a custom color scale for a grid:

```julia
using Colors
x = repeat([1:10], inner=[10])
y = repeat([1:10], outer=[10])
plot(x=x,y=y,color=x+y, Geom.rectbin, Scale.ContinuousColorScale(p -> RGB(0,p,0)))
```

Or we can use ```lab_gradient``` to construct a color gradient between 2 or more colors:

```julia
plot(x=x,y=y,color=x+y, Geom.rectbin,
     Scale.ContinuousColorScale(Scale.lab_gradient(color("green"),
                                                   color("white"),
                                                   color("red"))))
```

We can also start the color scale somewhere other than the bottom of the data range using ```minvalue```:

```julia
plot(x=x,y=y,color=x+y, Geom.rectbin,
     Scale.ContinuousColorScale(p -> RGB(0,p,0), minvalue=-20))
```
