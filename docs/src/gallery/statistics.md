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

## [`Stat.contour`](@ref)

```@example
using DataFrames, Gadfly
set_default_plot_size(21cm, 8cm)
expand_grid(xv, yv, n::Int) = vcat([[x y z] for x in xv, y in yv, z in 1:n]...)
a = expand_grid(6.0:10, 1.0:4, 3)
D= DataFrame(x= a[:,1], y=a[:,2], z=a[:,3].*a[:,1].*a[:,2], 
    level=string.("L",floor.(Int, a[:,3])) )
coord = Coord.cartesian(xmin=6, xmax=10, ymin=1, ymax=4)

plot(D, xgroup=:level, x=:x, y=:y, color=:z,
    Geom.subplot_grid(coord, layer(z=:z, Stat.contour(levels=7), Geom.line)),
    Scale.color_continuous(minvalue=0, maxvalue=120)
)
```

## [`Stat.density`](@ref)

```@example
using Colors, DataFrames, Gadfly, Distributions
set_default_plot_size(21cm, 8cm)
x = -4:0.1:4
Da = [DataFrame(x=x, ymax=pdf.(Normal(μ),x), ymin=0.0, u="μ=$μ") for μ in [-1,1]]
Db = [DataFrame(x=randn(200).+μ, u="μ=$μ") for μ in [-1,1]] 

p1 = plot(vcat(Da...), x=:x, y=:ymax, ymin=:ymin, ymax=:ymax, color=:u, 
    Geom.line, Geom.ribbon, Guide.ylabel("Density"),
    Theme(lowlight_color=c->RGBA{Float32}(c.r, c.g, c.b, 0.4)), 
    Guide.colorkey(title="", pos=[2.5,0.6]), Guide.title("Parametric PDF")
)
p2 = plot(vcat(Db...), x=:x, color=:u, 
    Stat.density(bandwidth=0.5), Geom.polygon(fill=true, preserve_order=true),
    Coord.cartesian(xmin=-4, xmax=4),
    Theme(lowlight_color=c->RGBA{Float32}(c.r, c.g, c.b, 0.4)),
    Guide.colorkey(title="", pos=[2.5,0.6]), Guide.title("Kernel PDF")
)
hstack(p1,p2)
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
using Colors, Compose, Gadfly, RDatasets
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
    Theme(point_size=2pt,
        lowlight_color=c->RGBA{Float32}(c.r, c.g, c.b, 0.2) )
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
