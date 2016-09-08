```@meta
Author = "David Chudzicki"
```

# Geom.path

Draw lines between points in the order they appear in the data. This is an
alias for [Geom.line](@ref) with `preserve_order=true`.

## Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `color` (optional): Group categorically by color.

## Examples

```@setup 1
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```
Here's a random walk in 2D:

```@example 1
n = 500
srand(1234)
xjumps = rand(n)-.5
yjumps = rand(n)-.5
plot(x=cumsum(xjumps),y=cumsum(yjumps),Geom.path())
```
Here's a spiral:

```@example 1
t = 0:0.2:8pi
plot(x=t.*cos(t), y=t.*sin(t), Geom.path)
```
