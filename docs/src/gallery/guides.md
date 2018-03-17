# Guides

## Guide.annotation

```@example
using Gadfly, Compose
set_default_plot_size(14cm, 8cm)
plot(sin, 0, 2pi, Guide.annotation(compose(context(),
     Shape.circle([pi/2, 3*pi/2], [1.0, -1.0], [2mm]),
     fill(nothing), stroke("orange"))))
```


## Guide.colorkey

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
Dsleep = dataset("ggplot2", "msleep")[[:Vore,:BrainWt,:BodyWt,:SleepTotal]]
DataFrames.dropmissing!(Dsleep)
Dsleep[:SleepTime] = Dsleep[:SleepTotal] .> 8
plot(Dsleep, x=:BodyWt, y=:BrainWt, Geom.point, color=:SleepTime, 
    Guide.colorkey(title="Sleep", labels=[">8","≤8"]),
    Scale.x_log10, Scale.y_log10 )
```

```@example
using Gadfly, Compose, RDatasets
set_default_plot_size(21cm, 8cm)
iris = dataset("datasets","iris")
pa = plot(iris, x=:SepalLength, y=:PetalLength, color=:Species, Geom.point,
      Theme(key_position=:inside) )
pb = plot(iris, x=:SepalLength, y=:PetalLength, color=:Species, Geom.point, 
      Guide.colorkey(title="Iris", pos=[0.05w,-0.28h]) )
hstack(pa, pb)
```
## Guide.manual_color_key

Combine two layers into a plot, and set a custom color of one layer.  Add a manual color key with labels that match the two layers.  (Note that "deepskyblue" is the default color for Geom.line and others.)

```@example
using Gadfly, DataFrames
set_default_plot_size(14cm, 8cm)
points = DataFrame(index=rand(0:10,30), val=rand(1:10,30))
line = DataFrame(val=rand(1:10,11), index = collect(0:10))
pointLayer = layer(points, x="index", y="val", Geom.point,Theme(default_color="green"))
lineLayer = layer(line, x="index", y="val", Geom.line)
plot(pointLayer, lineLayer,
     Guide.manual_color_key("Legend", ["Points", "Line"], ["green", "deepskyblue"]))
```


## Guide.title

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
plot(dataset("ggplot2", "diamonds"), x="Price", Geom.histogram,
    Guide.title("Diamond Price Distribution"))
```

## Guide.xlabel

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
p1 = plot(cos, 0, 2π, Guide.xlabel("Angle"));
p2 = plot(cos, 0, 2π, Guide.xlabel("Angle", orientation=:vertical));
p3 = plot(cos, 0, 2π, Guide.xlabel(nothing));
hstack(p1,p2,p3)
```


## Guide.xrug

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(x=rand(20), y=rand(20), Guide.xrug)
```


## Guide.xticks

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
ticks = [0.1, 0.3, 0.5]
p1 = plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks))
p2 = plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks, label=false))
p3 = plot(x=rand(10), y=rand(10), Geom.line,
          Guide.xticks(ticks=ticks, orientation=:vertical))
hstack(p1,p2,p3)
```

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(x=rand(1:10, 10), y=rand(1:10, 10), Geom.line, Guide.xticks(ticks=[1:9;]))
```

!!! note

    The `;` in `ticks=[1:9;]` is required to flatten the `1:9` range type into
    `[1,2,3,...]`. Alternatively, `collect` can be used in the following
    manner `ticks=collect(1:9)`.


## Guide.ylabel

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
p1 = plot(cos, 0, 2π, Guide.ylabel("cos(x)"));
p2 = plot(cos, 0, 2π, Guide.ylabel("cos(x)", orientation=:horizontal));
p3 = plot(cos, 0, 2π, Guide.ylabel(nothing));
hstack(p1,p2,p3)
```


## Guide.yrug

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(x=rand(20), y=rand(20), Guide.yrug)
```


## Guide.yticks

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
ticks = [0.2, 0.4, 0.6]
p1 = plot(x=rand(10), y=rand(10), Geom.line, Guide.yticks(ticks=ticks))
p2 = plot(x=rand(10), y=rand(10), Geom.line, Guide.yticks(ticks=ticks, label=false))
p3 = plot(x=rand(10), y=rand(10), Geom.line,
          Guide.yticks(ticks=ticks, orientation=:vertical))
hstack(p1,p2,p3)
```

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(x=rand(1:10, 10), y=rand(1:10, 10), Geom.line, Guide.yticks(ticks=[1:9;]))
```

!!! note

    The `;` in `ticks=[1:9;]` is required to flatten the `1:9` range type into
    `[1, 2, 3, ...]`. Alternatively, `collect` can be used in the following
    manner `ticks=collect(1:9)`.
