```@meta
Author = "Daniel C. Jones"
```

# Geom.subplot_grid

Draw multiple subplots in a grid organized by one or two categorial vectors.

## Aesthetics

  * `xgroup` (optional): Arrange subplots on the X-axis by categorial data.
  * `ygroup` (optional): Arrange subplots on the Y-axis by categorial data.
  * `free_y_axis` (optional): Whether the y-axis scales can differ across
  the subplots. Defaults to `false`. If `true`, scales are set appropriately for individual subplots.
  * `free_x_axis` (optional): Whether the x-axis scales can differ across
  the subplots. Defaults to `false`. If `true`, scales are set appropriately for individual subplots.

One or both of `xgroup` or `ygroup` must be bound. If only one, a single column
or row of subplots is drawn, if both, a grid.

## Arguments

```julia
Geom.subplot_grid(elements::Gadfly.ElementOrFunction...)
```

Unlike most geometries, [Geom.subplot_grid](@ref) is typically passed one or more
parameters. The constructor works for the most part like the `layer` function.
Arbitrary plot elements may be passed, while aesthetic bindings are inherited
from the parent plot.


## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
set_default_plot_size(20cm, 7.5cm)
plot(dataset("datasets", "OrchardSprays"),
     xgroup="Treatment", x="ColPos", y="RowPos", color="Decrease",
     Geom.subplot_grid(Geom.point))
```


```@example 1
set_default_plot_size(14cm, 25cm)
plot(dataset("vcd", "Suicide"), xgroup="Sex", ygroup="Method", x="Age", y="Freq",
     Geom.subplot_grid(Geom.bar))
```


### Multiple layers/dataframes:

```@setup 2
using RDatasets, DataFrames, Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 2
iris = dataset("datasets", "iris")
sp = unique(iris[:Species])
Dhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5, 2.5, 4.0], Species=repeat(sp, inner=[2]) )
# Try this one too:
# Dhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5], Species=repeat(sp[1:2], inner=[2]) )

plot(iris, xgroup=:Species, x=:SepalLength, y=:SepalWidth,
    Geom.subplot_grid(
        layer(Geom.point),
        layer(Dhl, xgroup=:Species, yintercept=:yint, Geom.hline(color="red", style=:dot) )
    )
)
```
or:  
```@example 2
plot(iris, xgroup=:Species,
    Geom.subplot_grid(
        layer(x=:SepalLength, y=:SepalWidth, Geom.point),
        layer(Dhl, xgroup=:Species, yintercept=:yint, Geom.hline(color="red", style=:dot)),
        ),
    Guide.xlabel("Xlabel"), Guide.ylabel("Ylabel")
)
```


### Free/fixed scales:

```@example 3
using RDatasets, Gadfly # hide
using DataFrames
set_default_plot_size(8cm, 12cm)

widedf = DataFrame(x = collect(1:10), var1 = collect(1:10), var2 = collect(1:10).^2)
longdf = stack(widedf, [:var1, :var2])
nothing # hide
```

Default behavior is for the axes' scales to be fixed across the subplots:

```@example 3
plot(longdf, ygroup="variable", x="x", y="value", Geom.subplot_grid(Geom.point))
```

We can change this default behavior where appropriate:

```@example 3
plot(longdf, ygroup="variable", x="x", y="value", Geom.subplot_grid(Geom.point, free_y_axis=true))
```

