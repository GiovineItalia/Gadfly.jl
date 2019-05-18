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
df = by(salaries, [:Rank,:Discipline], :Salary=>mean, :Salary=>std)
[df[i] = df.Salary_mean.+j*df.Salary_std for (i,j) in zip([:ymin, :ymax], [-1, 1.0])]
df[:label] = string.(round.(Int, df.Salary_mean))

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

## [`Stat.qq`](@ref)

```@example
using Gadfly, Distributions, Random
set_default_plot_size(21cm, 8cm)
Random.seed!(1234)
p1 = plot(x=rand(Normal(), 100), y=rand(Normal(), 100), Stat.qq, Geom.point)
p2 = plot(x=rand(Normal(), 100), y=Normal(), Stat.qq, Geom.point)
hstack(p1,p2)
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
