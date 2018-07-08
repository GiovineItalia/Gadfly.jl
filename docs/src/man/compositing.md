```@meta
Author = "Daniel C. Jones"
```

# Compositing

Gadfly also supports more advanced plot composition techniques like layering,
stacking, and faceting.

## Layers

Draw multiple layers onto the same plot with

```@setup 1
using Gadfly, Distributions, StatsBase
set_default_plot_size(14cm, 8cm)
```

```@example 1
d = rand(Normal(0,1),1000)
D = fit(Histogram,d)
x = (D.edges[1][1:end-1] + D.edges[1][2:end])/2
line = layer(x=x, y=cumsum(D.weights)/sum(D.weights), Geom.line, Theme(default_color="red"))
bars = layer(x=x, y=D.weights/maximum(D.weights), Geom.bar)
plot(line, bars)
```

Or if your data is in a DataFrame:

```julia
my_data = DataFrame(bins = collect(x),
                    probability = D.weights/maximum(D.weights),
                    cumulative = cumsum(D.weights)/sum(D.weights))
plot(my_data, layer(x=:bins, y=:cumulative, Geom.line, Theme(default_color="red")),
              layer(x=:bins, y=:probability, Geom.bar))
```

You can also pass different data frames to each layer:

```julia
layer(another_dataframe, x=:col1, y=:col2, Geom.point)
```

The ordering in which layers are laid on top of each other can be controlled
with the `order` keyword.  A higher order number will cause a layer to be drawn
on top of any layers with a lower number. If not specified, the default order
for a layer is 0.  Layers which have the same order number are ...

```@example 1
# using stacks (see below)
xs = rand(0:10, 100, 2)
p1 = plot(layer(x=xs[:, 1], color=[colorant"orange"], Geom.histogram),
          layer(x=xs[:, 2], Geom.histogram), Guide.title("Default ordering"))
p2 = plot(layer(x=xs[:, 1], color=[colorant"orange"], Geom.histogram, order=1),
          layer(x=xs[:, 2], Geom.histogram, order=2),
          Guide.title("Manual ordering"))
hstack(p1, p2)
```

Guide attributes may be added to a multi-layer plots:

```@example 1
plt=plot(layer(x=rand(10), y=rand(10), Geom.point),
         layer(x=rand(10), y=rand(10), Geom.line),
         Guide.xlabel("x label"),
         Guide.ylabel("y label"),
         Guide.title("Title"))
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

