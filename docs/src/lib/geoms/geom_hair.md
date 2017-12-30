```@meta
Author = "Mattriks"
```

# Geom.hair

Draws a line from the points to some `intercept` (base line). Looks like hairs standing on end, hence called a hair plot. Also known as a lollipop chart if the end points are plotted.

## Aesthetics

  * `x`: Position of points.
  * `y`: Position of points.
  * `color` (optional): Color.

## Arguments

  * `intercept`: Base of hairs. Defaults to zero. 
  * `orientation`: `:vertical` (default) or `:horizontal`

## Examples

```@setup 1
using Gadfly
Gadfly.set_default_plot_size(15cm, 7.5cm)
```

```@example 1
x= 1:10
s = [-1,-1,1,1,-1,-1,1,1,-1,-1]
pa = plot(x=x, y=x.^2, Geom.hair, Geom.point)
pb = plot(x=s.*(x.^2), y=x, Geom.hair(orientation=:horizontal), Geom.point, color=string.(s), Theme(key_position=:none))
hstack(pa, pb)
```




