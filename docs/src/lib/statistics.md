```@meta
Author = "Daniel C. Jones"
```

# [Statistics](@id lib_stat)

Statistics are functions taking as input one or more aesthetics, operating on
those values, then outputting to one or more aesthetics. For example, drawing of
boxplots typically uses the boxplot statistic ([`Stat.boxplot`](@ref)) that takes
as input the `x` and `y` aesthetic, and outputs the middle, and upper and lower
hinge, and upper and lower fence aesthetics.

```@index
Modules = [Stat]
```

```@autodocs
Modules = [Stat]
```
