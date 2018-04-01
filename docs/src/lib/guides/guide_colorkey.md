```@meta
Author = "Daniel C. Jones. Additions by Mattriks"
```

# Guide.colorkey

`Guide.colorkey` enables control of some fields of the auto-generated colorkey. Currently, you can change the colorkey title (for any plot), the item labels (for plots with a discrete color scale), and put the colorkey inside any plot. The fields can be named e.g. `Guide.colorkey(title="Group", labels=["A","B"], pos=[0w,0h])`, or given in order e.g. `Guide.colorkey("Group", ["A","B"], [0w,0h])`.

## Arguments
  * `title`: Legend title (for any plot)
  * `labels`: Legend item labels (for plots with a discrete color scale)
  * `pos`: [x,y] position of the colorkey inside any plot. Setting `Guide.colorkey(pos=)` will override the `Theme(key_position=)` setting. Setting `Theme(key_position=:inside)` without setting `pos` will place the key in the lower right quadrant of the plot (see example below)

## Colorkey position
`pos` can be given in relative or absolute units (do `using Compose` before plotting):  
* _Relative units_: e.g. [0.7w, 0.2h] will place the key in the lower right quadrant, [0.05w, -0.25h] in the upper left (see example below).  
* _Absolute units_: e.g. [0mm, 0mm] the key is left-centered, or use the plot scales like [x,y]. For the latter, the x-position will make sense, but the key will be offset below the y-position, because of the way the key is rendered.  


## Examples

```@setup 1
using RDatasets
using Compose
using Gadfly
Gadfly.set_default_plot_size(16cm, 8cm)
```

```@example 1
Dsleep = dataset("ggplot2", "msleep")[[:Vore,:BrainWt,:BodyWt,:SleepTotal]]
DataFrames.complete_cases!(Dsleep)
Dsleep[:SleepTime] = Dsleep[:SleepTotal] .> 8
plot(Dsleep, x=:BodyWt, y=:BrainWt, Geom.point, color=:SleepTime, 
    Guide.colorkey(title="Sleep", labels=[">8","≤8"]),
    Scale.x_log10, Scale.y_log10 )

```

```@example 1
iris = dataset("datasets","iris")
pa = plot(iris, x=:SepalLength, y=:PetalLength, color=:Species, Geom.point,
      Theme(key_position=:inside) )
pb = plot(iris, x=:SepalLength, y=:PetalLength, color=:Species, Geom.point, 
      Guide.colorkey(title="Iris", pos=[0.05w,-0.28h]) )
hstack(pa, pb)
```
