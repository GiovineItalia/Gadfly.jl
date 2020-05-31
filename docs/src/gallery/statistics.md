# Statistics

## [`Stat.binmean`](@ref)

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
p1 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
          Geom.point)
p2 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
          Stat.binmean, Geom.point)
hstack(p1,p2)
```

## [`Stat.density`](@ref)

```@example
using DataFrames, Gadfly, Distributions
set_default_plot_size(21cm, 8cm)
x = -4:0.1:4
Da = [DataFrame(x=x, ymax=pdf.(Normal(μ),x), ymin=0.0, u="μ=$μ") for μ in [-1,1]]
Db = [DataFrame(x=randn(200).+μ, u="μ=$μ") for μ in [-1,1]]

p1 = plot(vcat(Da...), x=:x, y=:ymax, ymin=:ymin, ymax=:ymax, color=:u, 
    Geom.line, Geom.ribbon, Guide.ylabel("Density"), Theme(alphas=[0.6]),
    Guide.colorkey(title="", pos=[2.5,0.6]), Guide.title("Parametric PDF")
)
p2 = plot(vcat(Db...), x=:x, color=:u, Theme(alphas=[0.6]),
    Stat.density(bandwidth=0.5), Geom.polygon(fill=true, preserve_order=true),
    Coord.cartesian(xmin=-4, xmax=4, ymin=0, ymax=0.4),
    Guide.colorkey(title="", pos=[2.5,0.6]), Guide.title("Kernel PDF")
)
hstack(p1,p2)
```

## [`Stat.dodge`](@ref)

```@example
using DataFrames, Gadfly, RDatasets, Statistics
set_default_plot_size(21cm, 8cm)
salaries = dataset("car","Salaries")
salaries.Salary /= 1000.0
salaries.Discipline = ["Discipline $(x)" for x in salaries.Discipline]
df = combine(groupby(salaries, [:Rank, :Discipline]), :Salary.=>mean)
df.label = string.(round.(Int, df.Salary_mean))

p1 = plot(df, x=:Discipline, y=:Salary_mean, color=:Rank, 
    Scale.x_discrete(levels=["Discipline A", "Discipline B"]),
    label=:label, Geom.label(position=:centered), Stat.dodge(position=:stack),
    Geom.bar(position=:stack)
)
p2 = plot(df, y=:Discipline, x=:Salary_mean, color=:Rank, 
    Coord.cartesian(yflip=true), Scale.y_discrete,
    label=:label, Geom.label(position=:right), Stat.dodge(axis=:y),
    Geom.bar(position=:dodge, orientation=:horizontal), 
    Scale.color_discrete(levels=["Prof", "AssocProf", "AsstProf"]),
    Guide.yticks(orientation=:vertical), Guide.ylabel(nothing)
)
hstack(p1, p2)
```

## [`Stat.func`](@ref)

```@example
using DataFrames, Gadfly
set_default_plot_size(14cm, 8cm)
sigmoid(x) = 1 ./ (1 .+ exp.(-x))
npoints = 30
gshift, x = rand([0,2], npoints), range(-9, 9, length=npoints)
y, ye = sigmoid(x+gshift), 0.2*rand(npoints)
df = DataFrame(x=x, y=y, ymin=y-ye, ymax=y+ye, g=gshift)

plot(y=[sigmoid, x->sigmoid(x+2)], xmin=[-10], xmax=[10],
    Geom.line, Stat.func(100), color=[0,2], Guide.xlabel("x"),
    layer(df, x=:x, y=:y, ymin=:ymin, ymax=:ymax, color=:g,
        Geom.point, Geom.errorbar, Stat.x_jitter(range=1)), 
    Scale.color_discrete_manual("deepskyblue","yellow3", levels=[0,2]),
    Guide.colorkey(title="Function", labels=["Sigmoid(x)", "Sigmoid(x+2)"]),
    Theme(errorbar_cap_length=0mm, key_position=:inside)
)
```

## [`Stat.qq`](@ref)

```@example
using Distributions, Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
iris, geyser = dataset.("datasets", ["iris", "faithful"])
df = combine(groupby(iris, :Species), :SepalLength=>(x->fit(Normal, x))=>:d)
ds2 = fit.([Normal, Uniform], [geyser.Eruptions])

yeqx(x=4:6) = layer(x=x, Geom.abline(color="gray80"))
xylabs = [Guide.xlabel("Theoretical q"), Guide.ylabel("Sample q")]
p1 = plot(df, x=:d, y=iris[:,1], color=:Species, Stat.qq, yeqx(4:8),
    xylabs..., Guide.title("3 Samples, 1 Distribution"))
p2 = plot(geyser, x=ds2, y=:Eruptions, color=["Normal","Uniform"], Stat.qq,
    yeqx(0:6), xylabs..., Guide.title("1 Sample, 2 Distributions"),
  Theme(discrete_highlight_color=c->nothing, alphas=[0.5], point_size=2pt)
)
hstack(p1, p2)
```

## [`Stat.smooth`](@ref)

```@example
using Compose, Gadfly, RDatasets
set_default_plot_size(21cm,8cm)
salaries = dataset("car","Salaries")
salaries.Salary /= 1000.0
salaries.Discipline = ["Discipline $(x)" for x in salaries.Discipline]

p = plot(salaries[salaries.Rank.=="Prof",:], x=:YrsService, y=:Salary, 
    color=:Sex, xgroup = :Discipline,
    Geom.subplot_grid(Geom.point,
  layer(Stat.smooth(method=:lm, levels=[0.95, 0.99]), Geom.line, Geom.ribbon)), 
    Scale.xgroup(levels=["Discipline A", "Discipline B"]),
    Guide.colorkey(title="", pos=[0.43w, -0.4h]), 
    Theme(point_size=2pt, alphas=[0.5])
)
```

```@example
using DataFrames, Gadfly
set_default_plot_size(14cm, 8cm)
x = range(0.1, stop=4.9, length=30)
D = DataFrame(x=x, y=x.+randn(length(x)))
p = plot(D, x=:x, y=:y, Geom.point,
  layer(Stat.smooth(method=:lm, levels=[0.90,0.99]), Geom.line, Geom.ribbon(fill=false)),
     Theme(lowlight_color=c->"gray", line_style=[:solid, :dot])
)
```


## [`Stat.step`](@ref)

```@example
using Gadfly, Random
set_default_plot_size(14cm, 8cm)
Random.seed!(1234)
plot(x=rand(25), y=rand(25), Stat.step, Geom.line)
```


## [`Stat.x_jitter`](@ref), [`Stat.y_jitter`](@ref)

```@example
using Gadfly, Distributions, Random
set_default_plot_size(14cm, 8cm)
Random.seed!(1234)
plot(x=rand(1:4, 500), y=rand(500), Stat.x_jitter(range=0.5), Geom.point)
```


## [`Stat.xticks`](@ref), [`Stat.yticks`](@ref)

```@example
using Gadfly, Random
set_default_plot_size(14cm, 8cm)
Random.seed!(1234)
plot(x=rand(10), y=rand(10), Stat.xticks(ticks=[0.0, 0.1, 0.9, 1.0]), Geom.point)
```
