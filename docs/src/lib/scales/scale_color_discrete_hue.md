```@meta
Author = "David Chudzicki"
```

# Scale.color_discrete_hue

Create a discrete color scale to be used for the plot. `Scale.color_discrete` is an
alias for [Scale.color_discrete_hue](@ref).

## Arguments

  * `f` (optional): A function `f(n)` that produces a vector of `n` colors. Usually [`distinguishable_colors`](https://github.com/JuliaGraphics/Colors.jl#distinguishable_colors) can be used for this, with parameters tuned to your liking.
  * `levels` (optional, keyword): Explicitly set levels used by the scale.
  * `order` (optional, keyword): A vector of integers giving a permutation of the levels
    default order.
  * `preserve_order` (optional, keyword): If set to `true`, orders levels as they appear in the data

## Examples

```@setup 1
using Colors, Gadfly
srand(1234)
```

There are 2 ways to change the discrete color scale:

* For a single plot, provide a color mapping function, i.e `f` above, to `Scale.color_discrete`:

```@example 1
function gen_colors(n)
  cs = distinguishable_colors(n,
      [colorant"#FE4365", colorant"#eca25c"], # seed colors
      lchoices=Float64[58, 45, 72.5, 90],     # lightness choices
      transform=c -> deuteranopic(c, 0.1),    # color transform
      cchoices=Float64[20,40],                # chroma choices
      hchoices=[75,51,35,120,180,210,270,310] # hue choices
  )

  convert(Vector{Color}, cs)
end

using RDatasets
iris = dataset("datasets", "iris")

plot(iris, x=:SepalLength, y=:SepalWidth, color=:Species,
     Geom.point, Scale.color_discrete(gen_colors))
```

* For a set of plots, provide a color mapping function to `style(discrete_colormap=)`, and use `Gadfly.push_theme()`. See [Themes](@ref).

```@example 1
Gadfly.push_theme( style(discrete_colormap=gen_colors) )

Gadfly.pop_theme() # hide
```

Also, you can force the use of a discrete scale on data that would otherwise receive a continuous scale:

```@example 1
plot(x=rand(12), y=rand(12), color=repeat([1,2,3], outer=[4]),
     Scale.color_discrete())
```
