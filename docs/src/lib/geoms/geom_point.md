```@meta
Author = "Daniel C. Jones"
```

# Geom.point

The point geometry is used to draw various types of scatterplots.

## Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `color` (optional): Point color.  Categorical data will choose maximally distinguishable colors from the LCHab color space.  Continuous data will map onto LCHab as well.  Colors can also be specified explicitly for each data point with a vector of colors of length(x).  A vector of length one specifies the color to use for all points.  Default is Theme.default_color.
  * `shape` (optional): Point shape.  Categorical data will cycle through Theme.point_shapes.  Shapes can also be specified explicitly for each data point with a vector of shapes of length(x).  A vector of length one specifies the shape to use for all points.  Default is Theme.point_shapes[1].
  * `size` (optional): Point size.  Categorical data and vectors of Ints will interpolate between Theme.point_size_{min,max}.  A continuous vector of AbstractFloats or Measures of length(x) specifies the size of each data point explicitly.  A vector of length one specifies the size to use for all points.  Default is Theme.point_size.

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point)
```

```@example 1
# Binding categorial data to the color aesthetic
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
     color="Species", Geom.point)
```

```@example 1
# Binding continuous data to the color aesthetic
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
     color="PetalLength", Geom.point)
```

```@example 1
# Binding categorial data to x
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.point)
```

```@example 1
# Binding categorical data to the shape aesthetic
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
        shape="Species", color="Species", Geom.point)
```

```@example 1
# Different colored layers
using Distributions
rdata = rand(MvNormal([0,0.],[1 0;0 1.]),100)
bdata = rand(MvNormal([1,0.],[1 0;0 1.]),100)
plot(layer(x=rdata[1,:], y=rdata[2,:], color=[colorant"red"], Geom.point),
     layer(x=bdata[1,:], y=bdata[2,:], color=[colorant"blue"], Geom.point))
```
