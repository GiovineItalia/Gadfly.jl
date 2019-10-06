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


## [`Geom.bar`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
plot(dataset("HistData", "ChestSizes"), x="Chest", y="Count", Geom.bar)
```

```@example
using Gadfly, RDatasets, DataFrames
set_default_plot_size(21cm, 8cm)

D = by(dataset("datasets","HairEyeColor"), [:Eye,:Sex], Frequency=:Freq=>sum)
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
p4 = plot(Dv, x=:x, y=:y, z=:z, color=:z,
          Coord.cartesian(xmin=1, xmax=22, ymin=1, ymax=16),
          Geom.point, Geom.contour(levels=10),
          style(line_width=0.5mm, point_size=0.2mm) )
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
plot(layer(x=xs, Geom.density, Theme(default_color="orange")), 
     layer(x=xs, Geom.density(bandwidth=0.0003), Theme(default_color="green")),
     layer(x=xs, Geom.density(bandwidth=0.25), Theme(default_color="purple")),
     Guide.manual_color_key("bandwidth", ["auto", "bw=0.0003", "bw=0.25"],
                            ["orange", "green", "purple"]))
```


## [`Geom.density2d`](@ref)

```@example
using Gadfly, Distributions
set_default_plot_size(14cm, 8cm)
plot(x=rand(Rayleigh(2),1000), y=rand(Rayleigh(2),1000),
     Geom.density2d(levels = x->maximum(x)*0.5.^collect(1:2:8)), Geom.point,
     Theme(key_position=:none),
     Scale.color_continuous(colormap=x->colorant"red"))
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
df = by(salaries, [:Rank,:Discipline], :Salary=>mean, :Salary=>std)
df.ymin, df.ymax = df.Salary_mean.-df.Salary_std, df.Salary_mean.+df.Salary_std
df.label = string.(round.(Int, df.Salary_mean))

p1 = plot(df, x=:Discipline, y=:Salary_mean, color=:Rank, 
    Scale.x_discrete(levels=["Discipline A", "Discipline B"]),
    ymin=:ymin, ymax=:ymax, Geom.errorbar, Stat.dodge,
    Geom.bar(position=:dodge), 
    Scale.color_discrete(levels=["Prof", "AssocProf", "AsstProf"]),
    Guide.colorkey(title="", pos=[0.76w, -0.38h]),
    Theme(bar_spacing=0mm, stroke_color=c->"black")
)
p2 = plot(df, y=:Discipline, x=:Salary_mean, color=:Rank, 
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
p1 = plot(D, x="Price", Geom.histogram)
p2 = plot(D, x="Price", color="Cut", Geom.histogram)
p3 = plot(D, x="Price", color="Cut", Geom.histogram(bincount=30))
p4 = plot(Dgamma, Coord.cartesian(xmin=0, xmax=20),
    layer(x->pdf(gamma, x), 0, 20, Geom.line, Theme(default_color="black")),
    layer(x=:x, Geom.histogram(bincount=20, density=true, limits=(min=0,))),
    Theme(default_color="bisque") )
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
using Gadfly, Colors, DataFrames, RDatasets
set_default_plot_size(21cm, 8cm)
theme1 = Theme(default_color=RGBA(0, 0.75, 1.0, 0.5))
D = DataFrame(x=[0.5,1], y=[0.5,1], x1=[0,0.5], y1=[0,0.5], x2=[1,1.5], y2=[1,1.5])
pa = plot(D, x=:x, y=:y, Geom.rectbin, theme1)
pb = plot(D, xmin=:x1, ymin=:y1, xmax=:x2, ymax=:y2, Geom.rect, theme1)
hstack(pa, pb)
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
set_default_plot_size(14cm, 14cm)
n = 1000
x, y = cumsum(randn(n)), cumsum(randn(n))
D = DataFrame(x1=x[1:end-1], y1=y[1:end-1], x2=x[2:end], y2=y[2:end], colv=1:n-1)
palettef(c::Float64) = get(ColorSchemes.viridis, c)

plot(D, x=:x1, y=:y1, xend=:x2, yend=:y2, 
     color = :colv, Geom.segment, Coord.cartesian(aspect_ratio=1.0),
     Scale.color_continuous(colormap=palettef, minvalue=0, maxvalue=1000)
)
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


## [`Geom.subplot_grid`](@ref)

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
Dsing.Voice = [x[1:5] for x in Dsing.VoicePart]
plot(Dsing, x=:VoicePart, y=:Height, color=:Voice, Geom.violin)
```
