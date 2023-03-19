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

Subplots have some inner and outer elements, including Guides and Scales. 
For example, place the guide inside `Geom.subplot_grid(...)` to change the subplot labels, or outside to change the outer plot labels.

```@example facet
haireye = dataset("datasets", "HairEyeColor")
palette = ["brown", "blue", "tan", "green"]

plot(haireye, y=:Sex, x=:Freq, color=:Eye, ygroup=:Hair,
    Geom.subplot_grid(Geom.bar(position=:stack, orientation=:horizontal),
        Guide.ylabel(orientation=:vertical) ),
    Scale.color_discrete_manual(palette...),
    Guide.colorkey(title="Eye\ncolor"),
    Guide.ylabel("Hair color"), Guide.xlabel("Frequency") )
```

More examples can be found in the plot gallery at [Geom.subplot_grid](@ref Gallery_Geom.subplot_grid) and [Scale.{x,y}group](@ref Gallery_Scale.xygroup).

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
theme1 = Theme(key_position=:none)
fig1a = plot(iris, x=:SepalLength, y=:SepalWidth, color=:Species, theme1,
          alpha=[0.6], size=:PetalLength, Scale.size_area(maxvalue=7))
fig1b = plot(iris, x=:SepalLength, color=:Species, Geom.density,
          Guide.ylabel("density"), Coord.cartesian(xmin=4, xmax=8), theme1)
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

For each of these commands, you can leave a panel blank by passing an empty `plot()`.
Other elements, e.g. `Scales` and `Guides`, can be added to blank plots.  If the plot contains aesthetic mappings,
use `Geom.blank`.

```@example stacks
using Compose # for w, h relative units
set_default_plot_size(21cm, 16cm) # hide
fig1c = plot(iris, x=:SepalWidth, color=:Species, Geom.density,
          Guide.ylabel("density"), Coord.cartesian(xmin=2, xmax=4.5), theme1)
fig1d = plot(iris, color=:Species, size=:PetalLength, Geom.blank,
          Scale.size_area(maxvalue=7), Theme(key_swatch_color="silver"),
          Guide.colorkey(title="Species", pos=[0.55w,-0.15h]),
          Guide.sizekey(title="PetalLength (cm)", pos=[0.2w, -0.10h]))
gridstack([fig1a fig1c; fig1b fig1d])
```

Note in this example, the Guide `pos` argument is in [width, height] relative units, which come from 
[Compose](http://giovineitalia.github.io/Compose.jl/latest/tutorial/#Measures-can-be-a-combination-of-absolute-and-relative-units-1).

Lastly, `title` can be used to add a descriptive string to the top of a stack.

```julia
title(hstack(p1,p2), "My creative title")
```


## Layers

_Introduction:_ Draw multiple layers onto the same plot by inputting `Layer` objects to `plot`.

```@setup layer
using Gadfly, RDatasets, Distributions
set_default_plot_size(14cm, 8cm)
iris = dataset("datasets", "iris")
```

```@example layer
xdata = sort(iris.SepalWidth)
ydata = cumsum(xdata)
line = layer(x=xdata, y=ydata, Geom.line, color=[colorant"red"], 
    Theme(line_width=1pt))
bars = layer(iris, x=:SepalWidth, Geom.bar)
plot(line, bars)
```

Note that here we used both the DataFrame and AbstractArrays interface to
[`layer`](@ref), as well a [`Theme`](@ref) object.  See [Themes](@ref) for more
information on the latter.

You can share the same DataFrame across different layers:

```julia
plot(iris,
     layer(x=:SepalLength, y=:SepalWidth),
     layer(x=:PetalLength, y=:PetalWidth, color=[colorant"red"]))
```

In this case, Gadfly labels the axes with the column names of first layer listed.
If this is not what is desired, Guides may be explicitly added.

```@example layer
plot(iris,
     layer(x=:SepalLength, y=:SepalWidth),
     layer(x=:PetalLength, y=:PetalWidth, color=[colorant"red"]),
     Guide.xlabel("length"), Guide.ylabel("width"), Guide.title("Iris data"),
     Guide.manual_color_key("",["Sepal","Petal"],
                            [Gadfly.current_theme().default_color,"red"]))
```

_Layer inputs_: `layer()` can input Geometries, Statistics, and Themes, but
not Scales, Coordinates, or Guides.

There are two rules about layers and Statistics:
1. Within a layer, all Geoms will use the layer `Stat` (if it's specified) e.g. `layer(Stat.smooth(method=:lm), Geom.line, Geom.ribbon)`
2. For Geoms outside of layers, Gadfly creates a new layer for each Geom, and each Stat is added to the newest layer e.g.

        xdata = range(-9, 9, length=30)
        plot(x=xdata, y=rand(30), Geom.point, Stat.binmean(n=5),
         Geom.line, Stat.step)

_Layers and Aesthetics_: Aesthetics can also be shared across layers:
```@example layer
plot(iris, Guide.colorkey(title=""),
    layer(x->0.4x-0.3, 0, 8, color=["Petal"]),
    layer(x=:SepalLength, y=:SepalWidth, color=["Sepal"]),
    layer(x=:PetalLength, y=:PetalWidth, color=["Petal"]),
    layer(x=[2.0], y=[4], shape=[Shape.star1], color=[colorant"red"], size=[8pt]),
    Theme(alphas=[0.7]))
```
And layers can inherit aesthetics from the plot:
```@example layer
set_default_plot_size(21cm, 8cm)
p1 = plot(iris, x=:SepalLength, y=:PetalLength,
    layer(Geom.smooth(method=:loess), color=["Smooth"]),
    layer(Geom.point, color=["Points"]))

p2 = plot(iris, x=:SepalLength, y=:PetalLength, color=:Species,
    Geom.smooth(method=:lm), Geom.point, alpha=[0.6],
    layer(Geom.smooth(method=:loess), color=[colorant"grey"], order=2))
hstack(p1, p2)
```
Note in some layers, it may be better to use specific Geoms e.g. `Geom.yerrorbar` rather than `Geom.errorbar`, since the latter will attempt to inherit aesthetics for both `Geom.xerrorbar` and `Geom.yerrobar`.

_Layer order_: the sequence in which layers are drawn, whether they overlap or not, can be
controlled with the `order` keyword.  Layers with lower order numbers are
rendered first.  If not specified, the default order for a layer is 0.  Layers
which have the same order number are drawn in the reverse order in which they
appear in `plot`'s input arguments.

```julia
bars = layer(iris, x=:SepalWidth, Geom.bar)
line = layer(iris, x=xdata, y=ydata, Geom.line, color=[colorant"red"],
             order=1)
plot(bars, line)
```
