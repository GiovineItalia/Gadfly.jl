```@meta
Author = "David Chudzicki"
```

# Scale.color_discrete_hue

Create a discrete color scale to be used for the plot. `Scale.discrete_color` is an
alias for [Scale.color_discrete_hue](@ref).

## Arguments

  * `levels` (optional): Explicitly set levels used by the scale. Order is
    respected.
  * `order` (optional): A vector of integers giving a permutation of the levels
    default order.

## Examples

```@example 1
using Gadfly # hide
srand(1234) # hide
nothing # hide
```

This forces the use of a discrete scale on data that would otherwise receive a continuous scale:

```@example 1
plot(x=rand(12), y=rand(12), color=repeat([1,2,3], outer=[4]),
     Scale.color_discrete())
```
