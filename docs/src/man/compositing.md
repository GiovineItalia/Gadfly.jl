```@meta
Author = "Daniel C. Jones"
```

# Compositing

Gadfly also supports more advanced plot composition techniques like layering,
stacking, and faceting.

## Layers

Draw multiple layers onto the same plot with

```@setup 1
using Gadfly, RDatasets, Distributions, StatsBase
set_default_plot_size(14cm, 8cm)
```

```@example 1
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

In this case, Gadfly uses labels the axes with the column names of first layer listed.
If this is not what is desired, 
Guides, coordinates, and scales may be added to a multi-layer plots, but not to
the layers individually:

```@example 1
plot(iris,
     layer(x=:SepalLength, y=:SepalWidth),
     layer(x=:PetalLength, y=:PetalWidth, Theme(default_color="red")),
     Guide.xlabel("length"), Guide.ylabel("width"), Guide.title("Iris data"),
     Guide.manual_color_key("",["Sepal","Petal"],
                            [Gadfly.current_theme().default_color,"red"]))
```

The ordering in which layers are laid on top of each other can be controlled
with the `order` keyword.  A higher order number will cause a layer to be drawn
on top of any layers with a lower number. If not specified, the default order
for a layer is 0.  Layers which have the same order number are drawn in the
reverse order they appear `plot`s input arguments.

```julia
bars = layer(iris, x=:SepalWidth, Geom.bar)
line = layer(iris, x=xdata, y=ydata, Geom.line, Theme(default_color="red"),
             order=1)
plot(bars, line)
```


## Stacks

Plots can also be stacked horizontally with [`hstack`](@ref) or vertically with
[`vstack`](@ref), and arranged into a rectangular array with `gridstack`.  This
allows more customization in regards to tick marks, axis labeling, and other
plot details than is available with [`Geom.subplot_grid`](@ref).

```@setup 2
using Gadfly, Compose
srand(123)
set_default_plot_size(14cm, 8cm)
```

```@example 2
p1 = plot(x=[1,2,3], y=[4,5,6]);
p2 = plot(x=[1,2,3], y=[6,7,8]);
hstack(p1,p2)
```

```@example 2
p3 = plot(x=[5,7,8], y=[8,9,10]);
p4 = plot(x=[5,7,8], y=[10,11,12]);

# these two are equivalent
vstack(hstack(p1,p2),hstack(p3,p4));
gridstack([p1 p2; p3 p4])
```

You can use `title` to add a descriptive string to the top of a stack

```@example 2
title(hstack(p3,p4), "My great data")
```

You can also leave panels empty in a stack by passing a `Compose.context()`
object

```@example 2
# empty panel
gridstack(Union{Plot,Compose.Context}[p1 p2; p3 Compose.context()])
```


## Facets

```@setup 3
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
```

```@example 3
iris = dataset("datasets", "iris")
plot(iris, xgroup="Species", x="SepalLength", y="SepalWidth",
     Geom.subplot_grid(Geom.point))
```

