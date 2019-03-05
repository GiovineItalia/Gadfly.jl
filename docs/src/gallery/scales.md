# Scales

## [`Scale.alpha_continuous`](@ref)

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
palettef = Scale.lab_gradient("darkgreen", "orange", "blue")
p1 = plot(x=1:10, y=rand(10), color=[1:10;], Geom.point,
    Scale.color_continuous(colormap=palettef, minvalue=0, maxvalue=10),
    Guide.title("Scale.color_continuous, Theme(alphas=[0.5])"),
    Theme(alphas=[0.5], continuous_highlight_color=identity,
        point_size=2mm)
)
p2 = plot(x=1:10, y=rand(10), alpha=[1:10;], Geom.point,
    Scale.alpha_continuous(minvalue=0, maxvalue=10),
    Guide.title("Scale.alpha_continuous, Theme(default_color=\"blue\")"),
    Theme(default_color="blue", discrete_highlight_color=c->"gray",
        point_size=2mm)
)
hstack(p1, p2)
```

## [`Scale.alpha_discrete`](@ref)

```@example
using DataFrames, Gadfly
set_default_plot_size(21cm, 8cm)
D = DataFrame(x=1:6, y=rand(6), Shape=repeat(["a","b","c"], outer=2))
coord = Coord.cartesian(xmin=0, xmax=7, ymin=0, ymax=1.0)
p1 = plot(D, x=:x, y=:y, color=:x,  coord,
    Scale.color_discrete, Geom.point, Geom.hair,
    Guide.title("Scale.color_discrete, Theme(alphas=[0.5])"),
    Theme(alphas=[0.5], discrete_highlight_color=identity,
        point_size=2mm)
)
p2 = plot(D, x=:x, y=:y, alpha=:x, shape=:Shape, coord,
    Scale.alpha_discrete, Geom.point, Geom.hair,
    Guide.title("Scale.alpha_discrete, Theme(default_color=\"green\")"),
    Theme(default_color="green", discrete_highlight_color=c->"gray",
        point_size=2mm, alphas=[0.0,0.2,0.4,0.6,0.8,1.0])
)
hstack(p1,p2)
```



## [`Scale.color_continuous`](@ref)

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
xdata, ydata, cdata = rand(12), rand(12), rand(12)
p1 = plot(x=xdata, y=ydata, color=cdata)
p2 = plot(x=xdata, y=ydata, color=cdata,
          Scale.color_continuous(minvalue=-1, maxvalue=1))
hstack(p1,p2)
```

```@example
using Gadfly, Colors
set_default_plot_size(21cm, 8cm)
x = repeat(collect(1:10).-0.5, inner=[10])
y = repeat(collect(1:10).-0.5, outer=[10])
p1 = plot(x=x, y=y, color=x+y, Geom.rectbin,
          Scale.color_continuous(colormap=p->RGB(0,p,0)))
p2 = plot(x=x, y=y, color=x+y, Geom.rectbin,
          Scale.color_continuous(colormap=Scale.lab_gradient("green", "white", "red")))
p3 = plot(x=x, y=y, color=x+y, Geom.rectbin,
          Scale.color_continuous(colormap=p->RGB(0,p,0), minvalue=-20))
hstack(p1,p2,p3)
```


## [`Scale.color_discrete_hue`](@ref)

```@example
using Gadfly, Colors, RDatasets, Random
set_default_plot_size(14cm, 8cm)
Random.seed!(1234)

function gen_colors(n)
    cs = distinguishable_colors(n,
                                [colorant"#FE4365", colorant"#eca25c"],
                                lchoices = Float64[58, 45, 72.5, 90],
                                transform = c -> deuteranopic(c, 0.1),
                                cchoices = Float64[20,40],
                                hchoices = [75,51,35,120,180,210,270,310])

    convert(Vector{Color}, cs)
end

iris = dataset("datasets", "iris")
plot(iris, x=:SepalLength, y=:SepalWidth, color=:Species,
     Geom.point, Scale.color_discrete(gen_colors))
```

```@example
using Gadfly, Colors, RDatasets, Random
set_default_plot_size(21cm, 8cm)
Random.seed!(1234)
xdata, ydata = rand(12), rand(12)
p1 = plot(x=xdata, y=ydata, color=repeat([1,2,3], outer=[4]))
p2 = plot(x=xdata, y=ydata, color=repeat([1,2,3], outer=[4]), Scale.color_discrete)
hstack(p1,p2)
```


## [`Scale.color_discrete_manual`](@ref)

```@example
using Gadfly, Random
Random.seed!(12345)
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


## [`Scale.color_none`](@ref)

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
xs = ys = 1:10.
zs = Float64[x^2*log(y) for x in xs, y in ys]
p1 = plot(x=xs, y=ys, z=zs, Geom.contour);
p2 = plot(x=xs, y=ys, z=zs, Geom.contour, Scale.color_none);
hstack(p1,p2)
```

## [`Scale.linestyle_discrete`](@ref)

```@example
using DataFrames, Gadfly, RDatasets
using StatsBase: winsor
set_default_plot_size(18cm, 8cm)

labs = [ "exp", "sqrt", "log", "winsor", "linear"]
funcs = [ x->60*(1.0.-exp.(-0.2*x)), x->sqrt.(x)*10, x->log.(x)*10, x->winsor(x, prop=0.15), x->x*0.6 ]
x = [1.0:30;]
D = vcat([DataFrame(x=x, y=f(x), linev=l) for (f,l) in zip(funcs, labs)]...)
D[134:136,:y] = NaN

p1 = plot(D, x=:x, y=:y, linestyle=:linev, Geom.line )
p2 = plot(dataset("datasets", "CO2"), x=:Conc, y=:Uptake, 
    group=:Plant, linestyle=:Treatment, color=:Type, Geom.line,
    Scale.linestyle_discrete(order=[2,1]),
    Theme(key_position=:top, key_title_font_size=-8mm) )
hstack(p1,p2)
```


## [`Scale.x_continuous`](@ref), [`Scale.y_continuous`](@ref)

```@example
using Gadfly, Random, Printf
set_default_plot_size(21cm, 8cm)
Random.seed!(1234)
p1 = plot(x=rand(10), y=rand(10), Scale.x_continuous(minvalue=-10, maxvalue=10))
p2 = plot(x=rand(10), y=rand(10), Scale.x_continuous(format=:scientific))
p3 = plot(x=rand(10), y=rand(10), Scale.x_continuous(labels=x -> @sprintf("%0.4f", x)))
hstack(p1,p2,p3)
```

```@example
using Gadfly, Random
set_default_plot_size(14cm, 8cm)
Random.seed!(1234)
plot(x=rand(10), y=rand(10), Scale.x_log)
```


## [`Scale.x_discrete`](@ref), [`Scale.y_discrete`](@ref)

```@example
using Gadfly, DataFrames, Random
set_default_plot_size(14cm, 8cm)
Random.seed!(1234)
# Treat numerical x data as categories
p1 = plot(x=rand(1:3, 20), y=rand(20), Scale.x_discrete)
# To perserve the order of the columns in the plot when plotting a DataFrame
df = DataFrame(v1 = randn(10), v2 = randn(10), v3 = randn(10))
p2 = plot(df, x=Col.index, y=Col.value, Scale.x_discrete(levels=names(df)))
hstack(p1,p2)
```

## [`Scale.xgroup`](@ref), [`Scale.ygroup`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm,14cm)
# mpg = miles per gallon
mpg = dataset("ggplot2","mpg")
xlabs = Dict(4=>"4 Cyl", 6=>"6 Cyl", 8=>"8 Cyl")  
ylabs = Dict("f"=>"front", "r"=>"rear", "4"=>"4-wheel")  
plot(mpg[mpg.Cyl.≠5,:], x=:Cty, y=:Hwy, color=:Class,
    xgroup=:Cyl, ygroup=:Drv,
    Geom.subplot_grid( Coord.cartesian(xmin=10), Geom.point,
      layer(slope=[1], intercept=[0], Geom.abline(color="silver", style=:dash))),
    Scale.xgroup(labels=i->xlabs[i], levels=[4,6,8]), 
    Scale.ygroup(labels=i->ylabs[i], levels=["f","4","r"]),  
    Guide.xlabel("City miles/gallon by Cylinders"),
    Guide.ylabel("Highway miles/gallon by Drive"),
    Theme(colorkey_swatch_shape=:circle)
)
```
