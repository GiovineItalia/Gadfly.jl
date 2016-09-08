```@meta
Author = "Alex Ryckman Mellnik"
```

# Guide.manual_color_key

Manually define a color key

## Arguments
  * `title`: Legend title
  * `labels`: Item labels
  * `colors`: Item colors

## Examples

Combine two layers into a plot, and set a custom color of one layer.  Add a manual color key with labels that match the two layers.  (Note that "deepskyblue" is the default color for Geom.line and others.)

```@setup 1
using DataFrames
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
points = DataFrame(index=rand(0:10,30), val=rand(1:10,30))
line = DataFrame(val=rand(1:10,11), index = collect(0:10))
pointLayer = layer(points, x="index", y="val", Geom.point,Theme(default_color=colorant"green"))
lineLayer = layer(line, x="index", y="val", Geom.line)
plot(pointLayer, lineLayer, Guide.manual_color_key("Legend", ["Points", "Line"], ["green", "deepskyblue"]))
```
