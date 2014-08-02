---
title: path
author: David Chudzicki
part: Geometry
order: 1015
...

Draw lines between points in the order they appear in the data. This is `Geom.line(preserve_order=true)`.

# Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `color` (optional): Group categorically by color.

# Examples

```{.julia hide="true" results="none"}
using Gadfly

Gadfly.set_default_plot_size(14cm, 8cm)
```
Here's a random walk in 2D:

```julia
n = 500
srand(1234)
xjumps = rand(n)-.5
yjumps = rand(n)-.5
plot(x=cumsum(xjumps),y=cumsum(yjumps),Geom.path())
```
Here's a spiral:

```julia
t = [0:0.2:8pi]
plot(x=t.*cos(t), y=t.*sin(t), Geom.path)
```
