```@meta
Author = "David Chudzicki"
```

# Scale.color_discrete_manual

Create a discrete color scale to be used for the plot.

## Arguments

  * `colors...`: an iterable collection of things that can be converted to colors with `Colors.color` (e.g. "tomato", RGB(1.0,0.388,0.278), colorant"#FF6347")
  * `levels` (optional): Explicitly set levels used by the scale. Order is
    respected.
  * `order` (optional): A vector of integers giving a permutation of the levels
    default order.

### Aesthetics Acted On

`color`

## Examples

```@setup 1
using Gadfly
srand(1234)
```

```@example 1
plot(x=rand(12), y=rand(12), color=repeat(["a","b","c"], outer=[4]),
     Scale.color_discrete_manual("red","purple","green"))
```

```@setup 2
using RDatasets
using DataFrames, Gadfly
set_default_plot_size(14cm, 8cm)
```

```@example 2
D = by(dataset("datasets","HairEyeColor"), [:Eye,:Sex], d->sum(d[:Freq]))
 rename!(D, :x1, :Frequency)
# Is there a hazel color?
palette = ["blue","brown","green","tan"]

pa= plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),
    Scale.color_discrete_manual(palette...)
)
pb= plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),
    Scale.color_discrete_manual(palette[4:-1:1]..., order=[4,3,2,1])
)
hstack(pa, pb)
```


