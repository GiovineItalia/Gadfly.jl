```@meta
Author = "Daniel C. Jones"
```

# Scale.color_discrete_manual

Create a discrete color scale to be used for the plot.

## Arguments

  * `colors...`: an iterable collection of things that can be converted to colors with `Colors.color` (such as strings naming colors, although a better choice is to use `colorant"colorname"`)
  * `levels` (optional): Explicitly set levels used by the scale. Order is
    respected.
  * `order` (optional): A vector of integers giving a permutation of the levels
    default order.

### Aesthetics Acted On

`color`

## Examples

```@example 1
using Gadfly # hide
srand(1234) # hide
nothing # hide
```

```@example 1
plot(x=rand(12), y=rand(12), color=repeat(["a","b","c"], outer=[4]),
     Scale.color_discrete_manual(colorant"red",colorant"purple",colorant"green"))
```
