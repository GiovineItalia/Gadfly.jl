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


## [`Stat.qq`](@ref)

```@example
using Gadfly, Distributions
set_default_plot_size(21cm, 8cm)
srand(1234)
p1 = plot(x=rand(Normal(), 100), y=rand(Normal(), 100), Stat.qq, Geom.point)
p2 = plot(x=rand(Normal(), 100), y=Normal(), Stat.qq, Geom.point)
hstack(p1,p2)
```


## [`Stat.step`](@ref)

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
srand(1234)
plot(x=rand(25), y=rand(25), Stat.step, Geom.line)
```


## [`Stat.x_jitter`](@ref), [`Stat.y_jitter`](@ref)

```@example
using Gadfly, Distributions
set_default_plot_size(14cm, 8cm)
srand(1234)
plot(x=rand(1:4, 500), y=rand(500), Stat.x_jitter(range=0.5), Geom.point)
```


## [`Stat.xticks`](@ref), [`Stat.yticks`](@ref)

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
srand(1234)
plot(x=rand(10), y=rand(10), Stat.xticks(ticks=[0.0, 0.1, 0.9, 1.0]), Geom.point)
```
