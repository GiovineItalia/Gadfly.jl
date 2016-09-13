```@meta
Author = "Daniel C. Jones"
```

# Stacks and Layers

**Gadfly** also supports more advanced plot composition techniques like stacking
and layering.

## Layers

Draw multiple layers onto the same plot with

```julia
plot(layer(x=rand(10), y=rand(10), Geom.point),
     layer(x=rand(10), y=rand(10), Geom.line))
```

Or if your data is in a DataFrame:

```julia
plot(my_data, layer(x="some_column1", y="some_column2", Geom.point),
              layer(x="some_column3", y="some_column4", Geom.line))
```

You can also pass different data frames to each layers:

```julia
layer(another_dataframe, x="col1", y="col2", Geom.point)
```

Ordering of layers can be controlled with the `order` keyword. A higher order
number will cause a layer to be drawn on top of any layers with a lower number.
If not specified, default order for a layer is 0.

```julia
plot(layer(x=rand(10), y=rand(10), Geom.point, order=1),
     layer(x=rand(10), y=rand(10), Geom.line, order=2))
```

Guide attributes may be added to a multi-layer plots:

```julia
plt=plot(layer(x=rand(10), y=rand(10), Geom.point),
         layer(x=rand(10), y=rand(10), Geom.line),
         Guide.XLabel("XLabel"),
         Guide.YLabel("YLabel"),
         Guide.Title("Title"));
```

## Stacks

Plots can also be stacked horizontally with `hstack` or vertically with `vstack`.
This allows more customization in regards to tick marks, axis labeling, and other
plot details than is available with [Geom.subplot_grid](@ref).

```julia
p1 = plot(x=[1,2,3], y=[4,5,6])
p2 = plot(x=[1,2,3], y=[6,7,8])
draw(PDF("p1and2.pdf", 6inch, 6inch), vstack(p1,p2))
p3 = plot(x=[5,7,8], y=[8,9,10])
p4 = plot(x=[5,7,8], y=[10,11,12])
draw(PDF("p1to4.pdf", 6inch, 9inch), vstack(hstack(p1,p2),hstack(p3,p4)))
```
