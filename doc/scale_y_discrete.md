---
title: y_discrete
author: Daniel Jones
part: Scale
order: 2002
...

Map data categorical to Cartesian coordinates. Unlike `Scale.y_continuous`, each
unique y value will be mapped to a equally spaced positions, regardless of
value.

By default continuous scales are applied to numerical data. If data consists of
numbers specifying categories, explicitly adding `Scale.y_discrete` is the
easiest way to get that data to plot appropriately.
# Arguments

  * `labels`: Either a `Function` or `nothing`. When a
    function is given, values are formatted using this function. The function
    should map a value in `x` to a string giving its label.
  * `levels`: If non-nothing, give values for the scale. Order will be respected
    and anything in the data that's not respresented in `levels` will be set to
    `NA`.
  * `order`: If non-nothing, give a vector of integers giving a permutation of
    the values pool of the data.



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


