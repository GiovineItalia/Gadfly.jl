---
title: y_discrete
author: Daniel Jones
part: Scale
order: 2002
...

Map data categorical to cartesian coordinates. Unlike `Scale.y_continuous`, each
unique y value will be mapped to a equally spaced positions, regardless of
value.

By default continuous scales are applied to numerical data. If data consists of
numbers specifying categories, explititly adding `Scale.y_discrete` is the
easiest way to get that data to plot appropriately.

# Aesthetics Acted On

`y`, `ymin`, `ymax`, `yintercept`

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(12cm, 8cm)
srand(1234)
```

```julia
# Tread numerical y data as categories
plot(x=rand(10), y=rand(5), Scale.y_discrete)
```


