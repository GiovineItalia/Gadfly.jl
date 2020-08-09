# Geometries

## [`Geom.abline`](@ref)

```@example
using Gadfly, RDatasets, Compose, Random
Random.seed!(123)
set_default_plot_size(21cm, 8cm)

p1 = plot(dataset("ggplot2", "mpg"),
     x="Cty", y="Hwy", label="Model", Geom.point, Geom.label,
     intercept=[0], slope=[1], Geom.abline(color="red", style=:dash),
     Guide.annotation(compose(context(), text(6,4, "y=x", hleft, vtop), fill("red"))))

x = [20*rand(20); exp(-3)]
D = DataFrame(x=x, y= exp.(-0.5*asinh.(x).+5) .+ 2*randn(length(x)))
abline = Geom.abline(color="red", style=:dash)
p2 = plot(D, x=:x, y=:y,  Geom.point,  Scale.x_asinh, Scale.y_log,
     intercept=[148], slope=[-0.5], abline)
hstack(p1, p2)
```

## [`Geom.band`](@ref), [`Geom.hband`](@ref), [`Geom.vband`](@ref)


```@example
using Colors, Dates, Gadfly, RDatasets

Dp = dataset("ggplot2","presidential")[3:end,:]
De = dataset("ggplot2","economics")
De.Unemploy /= 10^3

plot(De, x=:Date, y=:Unemploy, Geom.line,
    layer(Dp, xmin=:Start, xmax=:End, Geom.vband, color=:Party, alpha=[0.6]),
    Scale.color_discrete_manual("deepskyblue", "lightcoral"),
    Coord.cartesian(xmin=Date("1965-01-01"), ymax=12),
  Guide.xlabel("Time"), Guide.ylabel("Unemployment (x10³)"), Guide.colorkey(title=""),
    Theme(default_color="black", key_position=:top))
```

## [`Geom.bar`](@ref)

```@example
using ColorSchemes, DataFrames, Distributions, Gadfly
set_default_plot_size(21cm, 8cm)
x = range(-4, 4, length=30)
fn1(μ,x=x) = pdf.(Normal(μ, 1), x)
D = [DataFrame(x=x, y=fn1(μ), μ="$(μ)") for μ in [-1, 1]]
cpalette(p) = get(ColorSchemes.viridis, p)
p1 = plot(D[1], y=:y, x=:x, color=0:29, Geom.bar,
    Scale.color_continuous(colormap=cpalette),
    Theme(bar_spacing=-0.2mm, key_position=:none))
p2 = plot(D[1], x=:x, y=:y, Geom.bar, alpha=range(0.2,0.9, length=30))
p3 = plot(vcat(D...), x=:x, y=:y, color=:μ, alpha=[0.5],
    Geom.bar(position=:identity))
hstack(p1, p2, p3)
```

```@example
using Gadfly, RDatasets, DataFrames
set_default_plot_size(21cm, 8cm)

hecolor = dataset("datasets","HairEyeColor")
D = combine(groupby(hecolor, [:Eye,:Sex]), :Freq=>sum=>:Frequency)
p1 = plot(D, color=:Eye, y=:Frequency, x=:Sex, Geom.bar(position=:dodge))

palette = ["brown","blue","tan","green"]  # Is there a hazel color?

p2a = plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),
           Scale.color_discrete_manual(palette...));
p2b = plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),
           Scale.color_discrete_manual(palette[4:-1:1]..., order=[4,3,2,1]));

hstack(p1, p2a, p2b)
```

See [`Scale.color_discrete_manual`](@ref) for more information.


## [`Geom.beeswarm`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.beeswarm)
```

## [`Geom.blank`](@ref)

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
p1, p2 = plot(),  plot(x=1:10, y=rand(10), Geom.blank)
hstack(p1, p2)
```


## [`Geom.boxplot`](@ref)

```@example
using Compose, Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
singers, salaries = dataset("lattice", "singer"), dataset("car","Salaries")
salaries.Salary /= 1000.0
salaries.Discipline = ["Discipline $(x)" for x in salaries.Discipline]
p1 = plot(singers, x=:VoicePart, y=:Height, Geom.boxplot,
    Theme(default_color="MidnightBlue"))
p2 = plot(salaries, x=:Discipline, y=:Salary, color=:Rank,
    Scale.x_discrete(levels=["Discipline A", "Discipline B"]),
    Geom.boxplot, Theme(boxplot_spacing=0.1cx),
    Guide.colorkey(title="", pos=[0.78w,-0.4h])
)
hstack(p1, p2)
```


## [`Geom.candlestick`](@ref)

```@example
using Gadfly, MarketData
set_default_plot_size(21cm, 8cm)
ta = AAPL[end-50:end]
plot(
    x     = timestamp(ta),
    open  = values(ta.Open),
    high  = values(ta.High),
    low   = values(ta.Low),
    close = values(ta.Close),
    Geom.candlestick,
    Scale.color_discrete_manual("green", "red"),
    Scale.x_discrete,
)
```


## [`Geom.contour`](@ref)

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(z=(x,y) -> x*exp(-(x-round(Int, x))^2-y^2),
     xmin=[-8], xmax=[8], ymin=[-2], ymax=[2], Geom.contour)
```

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 16cm)
volcano = Matrix{Float64}(dataset("datasets", "volcano"))
p1 = plot(z=volcano, Geom.contour)
p2 = plot(z=volcano, Geom.contour(levels=[110.0, 150.0, 180.0, 190.0]))
p3 = plot(z=volcano, x=collect(0.0:10:860.0), y=collect(0.0:10:600.0),
          Geom.contour(levels=2))
Mv = volcano[1:4:end, 1:4:end]
Dv = vcat([DataFrame(x=[1:size(Mv,1);], y=j, z=Mv[:,j]) for j in 1:size(Mv,2)]...)
p4 = plot(Dv, x=:x, y=:y, z=:z,
          Coord.cartesian(xmin=1, xmax=22, ymin=1, ymax=16),
          layer(Geom.point, color=:z), Geom.contour(levels=10),
          Theme(line_width=0.5mm, point_size=1pt) )
gridstack([p1 p2; p3 p4])
```


## [`Geom.density`](@ref)

```@example
using Gadfly, RDatasets, Distributions
set_default_plot_size(21cm, 8cm)
p1 = plot(dataset("ggplot2", "diamonds"), x="Price", Geom.density)
p2 = plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
hstack(p1,p2)
```

```@example
using Gadfly, RDatasets, Distributions
set_default_plot_size(14cm, 8cm)
dist = MixtureModel(Normal, [(0.5, 0.2), (1, 0.1)])
xs = rand(dist, 10^5)
plot(layer(x=xs, Geom.density, color=["auto"]),
    layer(x=xs, Geom.density(bandwidth=0.0003), color=["bw=0.0003"]),
    layer(x=xs, Geom.density(bandwidth=0.25), color=["bw=0.25"]),
    Scale.color_discrete_manual("orange", "green", "purple"),
    Guide.colorkey(title="bandwidth"))
```


## [`Geom.density2d`](@ref)

```@example
using Gadfly, Distributions, RDatasets
set_default_plot_size(21cm, 8cm)
iris = dataset("datasets", "iris")
X = rand(Rayleigh(2), 1000,2)
levelf(x) = maximum(x)*0.5.^collect(1:2:8)
p1 = plot(x=X[:,1], y=X[:,2], Geom.density2d(levels=levelf), 
    Geom.point, Scale.color_continuous(colormap=c->colorant"red"),
    Theme(key_position=:none))
cs = repeat(Scale.default_discrete_colors(3), inner=50)
p2 = plot(iris, x=:SepalLength, y=:SepalWidth,
    layer(x=:SepalLength, y=:SepalWidth, color=cs),
    layer(Geom.density2d(levels=[0.1:0.1:0.4;]),  order=1),
    Scale.color_continuous, Guide.colorkey(title=""),
    Guide.manual_color_key("Iris", unique(iris.Species)),
    Theme(point_size=3pt, line_width=1.5pt))
hstack(p1, p2)
```


## [`Geom.ellipse`](@ref)

```@example
using RDatasets, Gadfly
set_default_plot_size(21cm, 8cm)
D = dataset("datasets","faithful")
D.g = D.Eruptions.>3.0
coord = Coord.cartesian(ymin=40, ymax=100)
pa = plot(D, coord,
    x=:Eruptions, y=:Waiting, group=:g,
    Geom.point, Geom.ellipse,
    Theme(lowlight_color=c->"gray") )
pb = plot(D, coord, Guide.ylabel(nothing),
    x=:Eruptions, y=:Waiting, color=:g,
    Geom.point, Geom.ellipse(levels=[0.95, 0.99]),
 Theme(key_position=:none, lowlight_color=identity, line_style=[:solid,:dot]))
pc = plot(D, coord, Guide.ylabel(nothing),
    x=:Eruptions, y=:Waiting, color=:g,
    Geom.point, Geom.ellipse(fill=true),
    layer(Geom.ellipse(levels=[0.99]), style(line_style=[:dot])),
    Theme(key_position=:none) )
hstack(pa,pb,pc)
```


## [`Geom.errorbar`](@ref)

```@example
using Gadfly, RDatasets, Distributions, Random
set_default_plot_size(21cm, 8cm)
Random.seed!(1234)
n = 10
sds = [1, 1/2, 1/4, 1/8, 1/16, 1/32]
ys = mean.(rand.(Normal.(0, sds), n))
df = DataFrame(x=1:length(sds), y=ys,
  mins=ys.-(1.96*sds/sqrt(n)), maxs=ys.+(1.96*sds/sqrt(n)),
    g=repeat(["a","b"], inner=3))
p1 = plot(df, x=1:length(sds), y=:y, ymin=:mins, ymax=:maxs, color=:g,
    Geom.point, Geom.errorbar)
p2 = plot(df, y=1:length(sds), x=:y, xmin=:mins, xmax=:maxs, color=:g,
    Geom.point, Geom.errorbar)
hstack(p1, p2)
```

```@example
using Compose, DataFrames, Gadfly, RDatasets, Statistics
set_default_plot_size(21cm, 8cm)
salaries = dataset("car","Salaries")
salaries.Salary /= 1000.0
salaries.Discipline = ["Discipline $(x)" for x in salaries.Discipline]
fn1(x, u=mean(x), s=std(x)) = (Salary=u, ymin=u-s, ymax=u+s, 
    label="$(round.(Int,u))")
df = combine(:Salary=>fn1, groupby(salaries, [:Rank, :Discipline]))

p1 = plot(df, x=:Discipline, y=:Salary, color=:Rank,
    Scale.x_discrete(levels=["Discipline A", "Discipline B"]),
    ymin=:ymin, ymax=:ymax, Geom.errorbar, Stat.dodge,
    Geom.bar(position=:dodge),
    Scale.color_discrete(levels=["Prof", "AssocProf", "AsstProf"]),
    Guide.colorkey(title="", pos=[0.76w, -0.38h]),
    Theme(bar_spacing=0mm, stroke_color=c->"black")
)
p2 = plot(df, y=:Discipline, x=:Salary, color=:Rank,
    Coord.cartesian(yflip=true), Scale.y_discrete,
    xmin=:ymin, xmax=:ymax, Geom.errorbar, Stat.dodge(axis=:y),
    Geom.bar(position=:dodge, orientation=:horizontal),
    Scale.color_discrete(levels=["Prof", "AssocProf", "AsstProf"]),
    Guide.yticks(orientation=:vertical), Guide.ylabel(nothing),
    Theme(bar_spacing=0mm, stroke_color=c->"gray")
)
hstack(p1,p2)
```


## [`Geom.hair`](@ref)

```@example
using Gadfly
set_default_plot_size(21cm, 8cm)
x= 1:10
s = [-1,-1,1,1,-1,-1,1,1,-1,-1]
pa = plot(x=x, y=x.^2, Geom.hair, Geom.point)
pb = plot(x=s.*(x.^2), y=x, color=string.(s),
          Geom.hair(orientation=:horizontal), Geom.point, Theme(key_position=:none))
hstack(pa, pb)
```


## [`Geom.hexbin`](@ref)

```@example
using Gadfly, Distributions
set_default_plot_size(21cm, 8cm)
X = rand(MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0]), 10000);
p1 = plot(x=X[1,:], y=X[2,:], Geom.hexbin)
p2 = plot(x=X[1,:], y=X[2,:], Geom.hexbin(xbincount=100, ybincount=100))
hstack(p1,p2)
```


## [`Geom.histogram`](@ref)

```@example
using Distributions, Gadfly, RDatasets
set_default_plot_size(21cm, 16cm)
D = dataset("ggplot2","diamonds")
gamma = Gamma(2, 2)
Dgamma = DataFrame(x=rand(gamma, 10^4))
p1 = plot(D, x="Price", color="Cut", Geom.histogram)
p2 = plot(D, x="Price", color="Cut", Geom.histogram(bincount=30))
p3 = plot(Dgamma, Coord.cartesian(xmin=0, xmax=20),
    layer(x->pdf(gamma, x), 0, 20, color=[colorant"black"]),
    layer(x=:x, Geom.histogram(bincount=20, density=true, limits=(min=0,)),
    color=[colorant"bisque"]))
a = repeat([0.75, 0.85], outer=40) # opacity
D2 = [DataFrame(x=rand(Normal(μ,1), 500), μ="$(μ)") for μ in [-1, 1]]
p4 = plot(vcat(D2...), x=:x,  color=:μ, alpha=[a;a],
    Geom.histogram(position=:identity, bincount=40, limits=(min=-4, max=4)),
    Scale.color_discrete_manual("skyblue","moccasin")
)
gridstack([p1 p2; p3 p4])
```


## [`Geom.histogram2d`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
p1 = plot(dataset("car", "Womenlf"), x="HIncome", y="Region", Geom.histogram2d)
p2 = plot(dataset("car", "UN"), x="GDP", y="InfantMortality",
          Scale.x_log10, Scale.y_log10, Geom.histogram2d)
p3 = plot(dataset("car", "UN"), x="GDP", y="InfantMortality",
          Scale.x_log10, Scale.y_log10, Geom.histogram2d(xbincount=30, ybincount=30))
hstack(p1,p2,p3)
```


## [`Geom.hline`](@ref), [`Geom.vline`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
p1 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
          xintercept=[5.0, 7.0], Geom.point, Geom.vline(style=[:solid,[1mm,1mm]]))
p2 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
          yintercept=[2.5, 4.0], Geom.point,
          Geom.hline(color=["orange","red"], size=[2mm,3mm]))
hstack(p1,p2)
```


## [`Geom.label`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
plot(dataset("ggplot2", "mpg"), x="Cty", y="Hwy", label="Model",
     Geom.point, Geom.label)
```

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
p1 = plot(dataset("MASS", "mammals"), x="Body", y="Brain", label=1,
     Scale.x_log10, Scale.y_log10, Geom.point, Geom.label)
p2 = plot(dataset("MASS", "mammals"), x="Body", y="Brain", label=1,
     Scale.x_log10, Scale.y_log10, Geom.label(position=:centered))
hstack(p1,p2)
```


## [`Geom.line`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
p1 = plot(dataset("lattice", "melanoma"), x="Year", y="Incidence", Geom.line)
p2 = plot(dataset("Zelig", "approval"), x="Month",  y="Approve", color="Year",
          Geom.line)
hstack(p1,p2)
```


## [`Geom.path`](@ref)

```@example
using Gadfly, Random
set_default_plot_size(21cm, 8cm)

n = 500
Random.seed!(1234)
xjumps = rand(n).-.5
yjumps = rand(n).-.5
p1 = plot(x=cumsum(xjumps),y=cumsum(yjumps),Geom.path)

t = 0:0.2:8pi
p2 = plot(x=t.*cos.(t), y=t.*sin.(t), Geom.path)

hstack(p1,p2)
```


## [`Geom.point`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 12cm)
D = dataset("datasets", "iris")
p1 = plot(D, x="SepalLength", y="SepalWidth", Geom.point);
p2 = plot(D, x="SepalLength", y="SepalWidth", color="PetalLength", Geom.point);
p3 = plot(D, x="SepalLength", y="SepalWidth", color="Species", Geom.point);
p4 = plot(D, x="SepalLength", y="SepalWidth", color="Species", shape="Species",
          Geom.point);
gridstack([p1 p2; p3 p4])
```


```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
plot(dataset("lattice", "singer"), x="VoicePart", y="Height", Geom.point)
```

```@example
using Gadfly, Distributions
set_default_plot_size(14cm, 8cm)
rdata = rand(MvNormal([0,0.],[1 0;0 1.]),100)
bdata = rand(MvNormal([1,0.],[1 0;0 1.]),100)
plot(layer(x=rdata[1,:], y=rdata[2,:], color=[colorant"red"], Geom.point),
     layer(x=bdata[1,:], y=bdata[2,:], color=[colorant"blue"], Geom.point))
```


## [`Geom.polygon`](@ref)

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(x=[0, 1, 1, 2, 2, 3, 3, 2, 2, 1, 1, 0, 4, 5, 5, 4],
     y=[0, 0, 1, 1, 0, 0, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3],
     group=["H", "H", "H", "H", "H", "H", "H", "H",
            "H", "H", "H", "H", "I", "I", "I", "I"],
     Geom.polygon(preserve_order=true, fill=true))
```


## [`Geom.rect`](@ref), [`Geom.rectbin`](@ref)

```@example
using Gadfly, DataFrames
set_default_plot_size(21cm, 8cm)
x1, y1, w1 = 0.5:10, rand(10), 0.09.+0.4*rand(10)
D = DataFrame(x=x1, y=rand(x1, 10), y1=y1, x2=x1.+w1, y2=y1.+w1, c=0:9)
p1 = plot(D, xmin=:x, ymin=:y1, xmax=:x2, ymax=:y2, color=[colorant"green"],
    alpha=1:10, Geom.rect, Scale.alpha_discrete)
p2 = plot(D, xmin=:x, ymin=:y1, xmax=:x2, ymax=:y2, color=:c, alpha=[0.7],
    Geom.rect, Guide.ylabel(nothing))
p3 = plot(D, x=:x, y=:y, color=:c, alpha=[0.5], Geom.rectbin, Scale.color_discrete)
hstack(p1, p2, p3)
```

```@example
using Gadfly, DataFrames, RDatasets
set_default_plot_size(14cm, 8cm)
plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP", Geom.rectbin)
```


## [`Geom.ribbon`](@ref)

```@example
using Gadfly, DataFrames, Distributions
set_default_plot_size(21cm, 8cm)
X = [cos.(0:0.1:20) sin.(0:0.1:20)]
x = -4:0.1:4
Da = [DataFrame(x=0:0.1:20, y=X[:,j], ymin=X[:,j].-0.5, ymax=X[:,j].+0.5, f="$f")  for (j,f) in enumerate(["cos","sin"])]
Db = [DataFrame(x=x, ymax=pdf.(Normal(μ),x), ymin=0.0, u="μ=$μ") for μ in [-1,1] ]

# In the line below, 0.6 is the color opacity
p1 = plot(vcat(Da...), x=:x, y=:y, ymin=:ymin, ymax=:ymax, color=:f,
    Geom.line, Geom.ribbon, Theme(alphas=[0.6])
)
p2 = plot(vcat(Db...), x = :x, y=:ymax, ymin = :ymin, ymax = :ymax,
    color = :u, alpha=:u, Theme(alphas=[0.8,0.2]),
    Geom.line, Geom.ribbon, Guide.ylabel("Density"),
    Guide.colorkey(title="", pos=[2.5,0.6]), Guide.title("Parametric PDF")
)
hstack(p1,p2)
```

## [`Geom.segment`](@ref)
```@example
using Gadfly, DataFrames, ColorSchemes
set_default_plot_size(21cm, 8cm)
n = 1000
x, y = cumsum(randn(n)), cumsum(randn(n))
D1 = DataFrame(x1=x[1:end-1], y1=y[1:end-1], x2=x[2:end], y2=y[2:end], colv=1:n-1)
palettef(c::Float64) = get(ColorSchemes.viridis, c)
a = range(0, stop=7π/4, length=8)+ 0.2*randn(8)
D2 = [DataFrame(x2=x, y2=x, x=x.+sin.(a)/r, y=x.+r*cos.(a),
        ls=rand(["A","A","B"], 8)) for (x,r) in zip([1,-1], [0.4,0.3])]

p1 = plot(D1, x=:x1, y=:y1, xend=:x2, yend=:y2,
     color=:colv, Geom.segment, Coord.cartesian(fixed=true),
     Scale.color_continuous(colormap=palettef, minvalue=0, maxvalue=1000)
)
p2 = plot(vcat(D2...), x=:x, y=:y, xend=:x2, yend=:y2,
     color=:x2, linestyle=:ls, Geom.point, Geom.segment,
     Scale.linestyle_discrete(levels=["A","B"]),
     Scale.color_discrete, Theme(key_position=:none, point_size=3.5pt))
hstack(p1, p2)
```


## [`Geom.smooth`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
x_data = 0.0:0.1:2.0
y_data = x_data.^2 + rand(length(x_data))
p1 = plot(x=x_data, y=y_data, Geom.point, Geom.smooth(method=:loess,smoothing=0.9))
p2 = plot(x=x_data, y=y_data, Geom.point, Geom.smooth(method=:loess,smoothing=0.2))
hstack(p1,p2)
```


## [`Geom.step`](@ref)

```@example
using Gadfly, Random
set_default_plot_size(14cm, 8cm)
Random.seed!(1234)
plot(x=rand(25), y=rand(25), Geom.step)
```


## [[`Geom.subplot_grid`](@ref)](@id Gallery_Geom.subplot_grid)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
plot(dataset("datasets", "OrchardSprays"),
     xgroup="Treatment", x="ColPos", y="RowPos", color="Decrease",
     Geom.subplot_grid(Geom.point))
```

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 25cm)
plot(dataset("vcd", "Suicide"), xgroup="Sex", ygroup="Method", x="Age", y="Freq",
     Geom.subplot_grid(Geom.bar))
```

```@example
using Gadfly, RDatasets, DataFrames
set_default_plot_size(14cm, 8cm)
iris = dataset("datasets", "iris")
sp = unique(iris.Species)
Dhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5, 2.5, 4.0], Species=repeat(sp, inner=[2]) )
# Try this one too:
# Dhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5], Species=repeat(sp[1:2], inner=[2]) )
plot(iris, xgroup=:Species, x=:SepalLength, y=:SepalWidth,
    Geom.subplot_grid(layer(Geom.point),
                      layer(Dhl, xgroup=:Species, yintercept=:yint,
                            Geom.hline(color="red", style=:dot))))
```

```@example
using Gadfly, RDatasets, DataFrames
set_default_plot_size(14cm, 8cm)
iris = dataset("datasets", "iris")
sp = unique(iris.Species)
Dhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5, 2.5, 4.0], Species=repeat(sp, inner=[2]) )
plot(iris, xgroup=:Species,
     Geom.subplot_grid(layer(x=:SepalLength, y=:SepalWidth, Geom.point),
                       layer(Dhl, xgroup=:Species, yintercept=:yint,
                             Geom.hline(color="red", style=:dot))),
     Guide.xlabel("Xlabel"), Guide.ylabel("Ylabel"))
```

```@example
using Gadfly, RDatasets, DataFrames
set_default_plot_size(14cm, 12cm)
widedf = DataFrame(x = 1:10, var1 = 1:10, var2 = (1:10).^2)
longdf = stack(widedf, [:var1, :var2])
p1 = plot(longdf, ygroup="variable", x="x", y="value", Geom.subplot_grid(Geom.point))
p2 = plot(longdf, ygroup="variable", x="x", y="value", Geom.subplot_grid(Geom.point,
          free_y_axis=true))
hstack(p1,p2)
```


## [`Geom.vector`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 14cm)

seals = RDatasets.dataset("ggplot2","seals")
seals.Latb = seals.Lat + seals.DeltaLat
seals.Longb = seals.Long + seals.DeltaLong
seals.Angle = atan.(seals.DeltaLat, seals.DeltaLong)

coord = Coord.cartesian(xmin=-175.0, xmax=-119, ymin=29, ymax=50)
# Geom.vector also needs scales for both axes:
xsc  = Scale.x_continuous(minvalue=-175.0, maxvalue=-119)
ysc  = Scale.y_continuous(minvalue=29, maxvalue=50)
colsc = Scale.color_continuous(minvalue=-3, maxvalue=3)

layer1 = layer(seals, x=:Long, y=:Lat, xend=:Longb, yend=:Latb, color=:Angle,
               Geom.vector)

plot(layer1, xsc, ysc, colsc, coord)
```


## [`Geom.vectorfield`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)

coord = Coord.cartesian(xmin=-2, xmax=2, ymin=-2, ymax=2)
p1 = plot(coord, z=(x,y)->x*exp(-(x^2+y^2)),
          xmin=[-2], xmax=[2], ymin=[-2], ymax=[2],
# or:     x=-2:0.25:2.0, y=-2:0.25:2.0,     
          Geom.vectorfield(scale=0.4, samples=17), Geom.contour(levels=6),
          Scale.x_continuous(minvalue=-2.0, maxvalue=2.0),
          Scale.y_continuous(minvalue=-2.0, maxvalue=2.0),
          Guide.xlabel("x"), Guide.ylabel("y"), Guide.colorkey(title="z"))

volcano = Matrix{Float64}(dataset("datasets", "volcano"))
volc = volcano[1:4:end, 1:4:end]
coord = Coord.cartesian(xmin=1, xmax=22, ymin=1, ymax=16)
p2 = plot(coord, z=volc, x=1.0:22, y=1.0:16,
          Geom.vectorfield(scale=0.05), Geom.contour(levels=7),
          Scale.x_continuous(minvalue=1.0, maxvalue=22.0),
          Scale.y_continuous(minvalue=1.0, maxvalue=16.0),
          Guide.xlabel("x"), Guide.ylabel("y"),
          Theme(key_position=:none))

hstack(p1,p2)
```


## [`Geom.violin`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
Dsing = dataset("lattice","singer")
Dsing.Voice = [x[1:5] for x in Array(Dsing.VoicePart)]
plot(Dsing, x=:VoicePart, y=:Height, color=:Voice, Geom.violin)
```
