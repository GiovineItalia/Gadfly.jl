```@meta
Author = "Daniel C. Jones"
```

# Compositing

Gadfly also supports more advanced plot composition techniques like faceting,
stacking, and layering.


## Facets

```@setup facet
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
```

```@example facet
iris = dataset("datasets", "iris")
plot(iris, xgroup="Species", x="SepalLength", y="SepalWidth",
     Geom.subplot_grid(Geom.point))
```


## Stacks

In addition to stacking plots horizontally as shown in the [Tutorial](@ref
Rendering), plots can also be vertically stacked and arranged in a grid.  This
allows more customization in regards to tick marks, axis labeling, and other
plot details than is available with [`Geom.subplot_grid`](@ref).

```@setup stacks
using Gadfly, RDatasets
iris = dataset("datasets", "iris")
fig1a = plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point)
fig1b = plot(iris, x=:SepalWidth, Geom.bar)
```

```@example stacks
fig1 = hstack(fig1a, fig1b)
vstack(p1,p2)
```

`hstack` and `vstack` can be composed to create arbitrary arrangements
of panels.

```@julia
vstack(hstack(p1,p2),hstack(p3,p4,p5));
```

If all rows or columns have the same number of panels, it's easiest
to used `gridstack`.

```julia
gridstack([p1 p2; p3 p4])
```

For each of these commands, you can leave a panel empty by passing in a
`Compose.context()` object.

```julia
gridstack(Union{Plot,Compose.Context}[p1 p2; p3 Compose.context()])
```

Note that in this case the Array must be explicitly typed.

Lastly, `title` can be used to add a descriptive string to the top of a stack.

```julia
title(hstack(p3,p4), "My great data")
```


## Layers

Draw multiple layers onto the same plot with

```@setup layer
using Gadfly, RDatasets, Distributions, StatsBase
set_default_plot_size(14cm, 8cm)
```

```@example layer
iris = dataset("datasets", "iris")
xdata = sort(iris[:SepalWidth])
ydata = cumsum(xdata)
line = layer(iris, x=xdata, y=ydata, Geom.line, Theme(default_color="red"))
bars = layer(iris, x=:SepalWidth, Geom.bar)
plot(line, bars)
```

You can also share the same data frame across different layers:

```julia
plot(iris,
     layer(x=:SepalLength, y=:SepalWidth),
     layer(x=:PetalLength, y=:PetalWidth, Theme(default_color="red")))
```

In this case, Gadfly labels the axes with the column names of first layer listed.
If this is not what is desired, Guides may be explicitly added.

```@example layer
plot(iris,
     layer(x=:SepalLength, y=:SepalWidth),
     layer(x=:PetalLength, y=:PetalWidth, Theme(default_color="red")),
     Guide.xlabel("length"), Guide.ylabel("width"), Guide.title("Iris data"),
     Guide.manual_color_key("",["Sepal","Petal"],
                            [Gadfly.current_theme().default_color,"red"]))
```

Note that while `layer` can input Geometries, Statistics, and Themes, it can
not input Scales, Coordinates, or Guides.

The sequence in which layers are drawn, whether they overlap or not, can be
controlled with the `order` keyword.  Layers with lower order numbers are
rendered first.  If not specified, the default order for a layer is 0.  Layers
which have the same order number are drawn in the reverse order in which they
appear in `plot`s input arguments.

```julia
bars = layer(iris, x=:SepalWidth, Geom.bar)
line = layer(iris, x=xdata, y=ydata, Geom.line, Theme(default_color="red"),
             order=1)
plot(bars, line)
```
