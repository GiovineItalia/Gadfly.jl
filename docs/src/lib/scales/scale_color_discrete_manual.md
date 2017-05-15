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
