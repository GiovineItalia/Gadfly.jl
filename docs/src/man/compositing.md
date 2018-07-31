```@meta
Author = "Daniel C. Jones"
```

# Compositing

Gadfly supports advanced plot composition techniques like faceting, stacking,
and layering.


## Facets

It is easy to make multiple plots that all share a common dataset and axis.

```@example facet
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm) # hide
iris = dataset("datasets", "iris")
plot(iris, xgroup="Species", x="SepalLength", y="SepalWidth",
     Geom.subplot_grid(Geom.point))
```

[`Geom.subplot_grid`](@ref) can similarly arrange plots vertically, or
even in a 2D grid if there are two shared axes.


## Stacks

To composite plots derived from different datasets, or the same data but
different axes, a declarative interface is used.  The [Tutorial](@ref Rendering)
showed how such disparate plots can be horizontally arranged with `hstack`.
Here we illustrate how to vertically stack them with `vstack` or arrange them
in a grid with `gridstack`.  These commands allow more customization in regards
to tick marks, axis labeling, and other plot details than is available with
[`Geom.subplot_grid`](@ref).

```@setup stacks
using Gadfly, RDatasets, Compose
iris = dataset("datasets", "iris")
```

```@example stacks
set_default_plot_size(14cm, 16cm) # hide
fig1a = plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point)
fig1b = plot(iris, x=:SepalLength, Geom.density,
             Guide.ylabel("density"), Coord.cartesian(xmin=4, xmax=8))
vstack(fig1a,fig1b)
```

`hstack` and `vstack` can be composed to create arbitrary arrangements
of panels.

```julia
vstack(hstack(p1,p2),hstack(p3,p4,p5))
```

If all rows or columns have the same number of panels, it's easiest
to use `gridstack`.

```julia
gridstack([p1 p2; p3 p4])
```

For each of these commands, you can leave a panel empty by passing in a
`Compose.context()` object.

```@example stacks
using Compose
set_default_plot_size(21cm, 16cm) # hide
fig1c = plot(iris, x=:SepalWidth, Geom.density,
             Guide.ylabel("density"), Coord.cartesian(xmin=2, xmax=4.5))
gridstack(Union{Plot,Compose.Context}[fig1a fig1c; fig1b Compose.context()])
```

Note that in this case the array must be explicitly typed.

Lastly, `title` can be used to add a descriptive string to the top of a stack.

```julia
title(hstack(p1,p2), "My creative title")
```


## Layers

Draw multiple layers onto the same plot by inputing `Layer` objects to `plot`.

```@setup layer
using Gadfly, RDatasets, Distributions, StatsBase
set_default_plot_size(14cm, 8cm)
iris = dataset("datasets", "iris")
```

```@example layer
xdata = sort(iris[:SepalWidth])
ydata = cumsum(xdata)
line = layer(x=xdata, y=ydata, Geom.line, Theme(default_color="red"))
bars = layer(iris, x=:SepalWidth, Geom.bar)
plot(line, bars)
```

Note that here we used both the DataFrame and AbstractArrays interface to
[`layer`](@ref), as well a [`Theme`](@ref) object.  See [Themes](@ref) for more
information on the latter.

You can also share the same DataFrame across different layers:

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
appear in `plot`'s input arguments.

```julia
bars = layer(iris, x=:SepalWidth, Geom.bar)
line = layer(iris, x=xdata, y=ydata, Geom.line, Theme(default_color="red"),
             order=1)
plot(bars, line)
```
