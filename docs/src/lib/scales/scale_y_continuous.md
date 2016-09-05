```@meta
Author = "Daniel C. Jones"
```

# Scale.y_continuous

Map numerical data to y positions in cartesian coordinates.

## Arguments

  * `minvalue`: Set scale lower bound to be ≤ this value.
  * `maxvalue`: Set scale lower bound to be ≥ this value.

!!! note

    `minvalue` and `maxvalue` here are soft bounds, Gadfly may choose to ignore
    them when constructing an optimal plot. Use [Coord.cartesian](@ref) to enforce
    a hard bound.

  * `labels`: Either a `Function` or `nothing`. When a
    function is given, values are formatted using this function. The function
    should map a value in `x` to a string giving its label. If the scale
    applies a transformation, transformed label values will be passed to this
    function.
  * `format`: How numbers should be formatted. One of `:plain`, `:scientific`,
    `:engineering`, or `:auto`. The default in `:auto` which prints very large or very small
    numbers in scientific notation, and other numbers plainly.
  * `scalable`: When set to false, scale is fixed when zooming (default: true)

### Variations

A number of transformed continuous scales are provided.

  * `Scale.y_continuous` (scale without any transformation).
  * `Scale.y_log10`
  * `Scale.y_log2`
  * `Scale.y_log`
  * `Scale.y_asinh`
  * `Scale.y_sqrt`


### Aesthetics Acted On

`y`, `ymin`, `ymax`, `yintercept`

## Examples

```@setup 1
using RDatasets
using Gadfly
srand(1234)
```

```@example 1
# Transform both dimensions
plot(x=rand(10), y=rand(10), Scale.y_log)
```

```@example 1
# Force the viewport
plot(x=rand(10), y=rand(10), Scale.y_continuous(minvalue=-10, maxvalue=10))
```

```@example 1
# Use scientific notation
plot(x=rand(10), y=rand(10), Scale.y_continuous(format=:scientific))
```

```@example 1
# Use manual formatting
plot(x=rand(10), y=rand(10), Scale.y_continuous(labels=y -> @sprintf("%0.4f", y)))
```
