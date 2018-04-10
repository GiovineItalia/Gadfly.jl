# Scales

## Scale.color_continuous

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
srand(1234)
# The data are all between 0 and 1, but the color scale goes from -1 to 1.
# For example, you might do this to force a consistent color scale between plots.
plot(x=rand(12), y=rand(12), color=rand(12),
     Scale.color_continuous(minvalue=-1, maxvalue=1))
```

```@example
#Define a custom color scale for a grid:
using Gadfly, Colors
set_default_plot_size(21cm, 8cm)
x = repeat(collect(1:10)-0.5, inner=[10])
y = repeat(collect(1:10)-0.5, outer=[10])
p1 = plot(x=x, y=y, color=x+y, Geom.rectbin,
          Scale.color_continuous(colormap=p->RGB(0,p,0)))
#Or we can use `lab_gradient` to construct a color gradient between 2 or more colors:
p2 = plot(x=x, y=y, color=x+y, Geom.rectbin,
          Scale.color_continuous(colormap=Scale.lab_gradient("green", "white", "red")))
#We can also start the color scale somewhere other than the bottom of the data range
#using `minvalue`:
p3 = plot(x=x, y=y, color=x+y, Geom.rectbin,
          Scale.color_continuous(colormap=p->RGB(0,p,0), minvalue=-20))
hstack(p1,p2,p3)
```


## Scale.color_discrete_hue

```@example
using Gadfly, Colors, RDatasets
set_default_plot_size(14cm, 8cm)
srand(1234)

#You can set a discrete color scale of your choice in a plot.

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

iris = dataset("datasets", "iris")
plot(iris, x=:SepalLength, y=:SepalWidth, color=:Species,
     Geom.point, Scale.color_discrete(gen_colors))
```

```@example
using Gadfly, Colors, RDatasets
set_default_plot_size(14cm, 8cm)
srand(1234)
#You can force the use of a discrete scale on data that would otherwise receive
#a continuous scale:
plot(x=rand(12), y=rand(12), color=repeat([1,2,3], outer=[4]),
     Scale.color_discrete())
```

!!! note

    To set a default color scale for plots, you can set it in the current Theme
    (see [Themes](@ref)) using `push_theme`, using `style` to modify the
    current theme.

    ```
    Gadfly.push_theme(style(discrete_color_scale=Scale.color_discrete(gen_colors)))
    # your code here
    Gadfly.pop_theme()```
    ```


## Scale.color_discrete_manual

```@example
using Gadfly
srand(12345)
set_default_plot_size(14cm, 8cm)
plot(x=rand(12), y=rand(12), color=repeat(["a","b","c"], outer=[4]),
     Scale.color_discrete_manual("red","purple","green"))
```

```@example
using Gadfly, RDatasets, DataFrames
set_default_plot_size(14cm, 8cm)
D = by(dataset("datasets","HairEyeColor"), [:Eye,:Sex], d->sum(d[:Freq]))
 rename!(D, :x1, :Frequency)
palette = ["brown","blue","tan","green"] # Is there a hazel color?

pa = plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),
         Scale.color_discrete_manual(palette...))
pb = plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),
         Scale.color_discrete_manual(palette[4:-1:1]..., order=[4,3,2,1]))
hstack(pa,pb)
```


## Scale.color_none

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
xs = 1:10.
ys = 1:10.
zs = Float64[x^2*log(y) for x in xs, y in ys]
plot(x=xs, y=ys, z=zs, Geom.contour, Scale.color_none)
```


## Scale.x_continuous

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
srand(1234)
# Force the viewport
p1 = plot(x=rand(10), y=rand(10), Scale.x_continuous(minvalue=-10, maxvalue=10))
# Use scientific notation
p2 = plot(x=rand(10), y=rand(10), Scale.x_continuous(format=:scientific))
# Use manual formatting
p3 = plot(x=rand(10), y=rand(10), Scale.x_continuous(labels=x -> @sprintf("%0.4f", x)))
hstack(p1,p2,p3)
```

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
srand(1234)
# Transform both dimensions
plot(x=rand(10), y=rand(10), Scale.x_log)
```


## Scale.x_discrete

```@example
using Gadfly, DataFrames
set_default_plot_size(14cm, 8cm)
srand(1234)
# Treat numerical x data as categories
p1 = plot(x=rand(1:3, 20), y=rand(20), Scale.x_discrete)
# To perserve the order of the columns in the plot when plotting a DataFrame
df = DataFrame(v1 = randn(10), v2 = randn(10), v3 = randn(10))
p2 = plot(df, x=Col.index, y=Col.value, Scale.x_discrete(levels=names(df)))
hstack(p1,p2)
```


## Scale.y_continuous

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
srand(1234)
# Force the viewport
p1 = plot(x=rand(10), y=rand(10), Scale.y_continuous(minvalue=-10, maxvalue=10))
# Use scientific notation
p2 = plot(x=rand(10), y=rand(10), Scale.y_continuous(format=:scientific))
# Use manual formatting
p3 = plot(x=rand(10), y=rand(10), Scale.y_continuous(labels=y -> @sprintf("%0.4f", y)))
hstack(p1,p2,p3)
```

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
srand(1234)
# Transform both dimensions
plot(x=rand(10), y=rand(10), Scale.y_log)
```


## Scale.y_discrete

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
srand(1234)
# Treat numerical y data as categories
plot(x=rand(20), y=rand(1:3, 20), Scale.y_discrete, Geom.point)
```
