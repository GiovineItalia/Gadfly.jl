---
title: x_discrete
author: Daniel Jones
part: Scale
order: 2002
...

Map data categorical to cartesian coordinates. Unlike `Scale.x_continuous`, each
unique x value will be mapped to a equally spaced positions, regardless of
value.

By default continuous scales are applied to numerical data. If data consists of
numbers specifying categories, explititly adding `Scale.x_discrete` is the
easiest way to get that data to plot appropriately.

# Aesthetics Acted On

`x`, `xmin`, `xmax`, `xintercept`

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(12cm, 8cm)
srand(1234)
```

```julia
# Tread numerical x data as categories
plot(x=rand(3), y=rand(10), Scale.x_discrete)
```


