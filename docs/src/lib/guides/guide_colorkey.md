```@meta
Author = "Daniel C. Jones. Additions by Mattriks"
```

# Guide.colorkey

`Guide.colorkey` enables control of some fields of the auto-generated colorkey. Currently, you can change the colorkey title (for any plot), and the item labels (for plots with a discrete color scale). The fields can be named e.g. `Guide.colorkey(title="Group", labels=["A","B"])`, or given in order e.g. `Guide.colorkey("Group", ["A","B"])`.

## Arguments
  * `title`: Legend title (for any plot)
  * `labels`: Legend item labels (for plots with a discrete color scale)

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 7cm)
```

```@example 1
Dsleep = dataset("ggplot2", "msleep")[[:Vore,:BrainWt,:BodyWt,:SleepTotal]]
completecases!(Dsleep)
Dsleep[:SleepTime] = Dsleep[:SleepTotal] .> 8
plot(Dsleep, x=:BodyWt, y=:BrainWt, Geom.point, color=:SleepTime, 
    Guide.colorkey(title="Sleep \n(hours/day)\n ", labels=[">8","≤8"]),
    Scale.x_log10, Scale.y_log10 )

```
