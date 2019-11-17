```@meta
Author = "Daniel C. Jones"
```

# Plotting

Most interaction with Gadfly is through the `plot` function. Plots are
described by binding data to aesthetics, and specifying a number of
elements including [Scales](@ref lib_scale), [Coordinates](@ref lib_coord),
[Guides](@ref lib_guide), and [Geometries](@ref lib_geom).  Aesthetics are a
set of special named variables that are mapped to a geometry. How this
mapping occurs is defined by the elements.

This "grammar of graphics" approach tries to avoid arcane incantations and
special cases, instead approaching the problem as if one were drawing a wiring
diagram: data is connected to aesthetics, which act as input leads, and
elements, each self-contained with well-defined inputs and outputs, are
connected and combined to produce the desired result.


## Functions and Expressions

Along with the standard plot methods operating on DataFrames and Arrays
described in the [Tutorial](@ref), Gadfly has some special signatures to make
plotting functions and expressions more convenient.

```julia
plot(f::Function, lower, upper, elements...; mapping...)
plot(fs::Vector{T}, lower, upper, elements...; mapping...) where T <: Base.Callable
plot(f::Function, xmin, xmax, ymin, ymax, elements...; mapping...)
spy(M::AbstractMatrix, elements...; mapping...) -> Plot
```

For example:

```@setup 1
using Gadfly, Random
set_default_plot_size(21cm, 8cm)
Random.seed!(12345)
```

```@example 1
p1 = plot([sin,cos], 0, 2pi)
p2 = plot((x,y)->sin(x)+cos(y), 0, 2pi, 0, 2pi)
p3 = spy(ones(33)*sin.(0:(pi/16):2pi)' + cos.(0:(pi/16):2pi)*ones(33)')
hstack(p1,p2,p3)
```


## Adding to a plot
Another feature is that a plot can be added to incrementally, using `push!`. 

```@setup 3
using Compose, Gadfly
set_default_plot_size(14cm, 8cm)
```

```@example 3
p = plot(x=[0,6], y=[0,6], Geom.blank)
push!(p, layer(x=[2,4], y=[2,4], size=[1.4142cx], color=[colorant"gold"]))
push!(p, Coord.cartesian(fixed=true))
push!(p, Guide.title("My Awesome Plot"))
```



## Wide-formatted data

Gadfly is designed to plot data in so-called "long form", in which data that
is of the same type, or measuring the same quantity, are stored in a single
column, and any factors or groups are specified by additional columns. This
is how data is typically stored in a database.

Sometimes data tables are organized by grouping values of the same type into
multiple columns, with a column name used to distinguish the grouping. We
refer to this as "wide form" data.

To illustrate the difference consider some historical London birth rate data.

```julia
births = RDatasets.dataset("HistData", "Arbuthnot")[:,[:Year, :Males, :Females]]
```

| Row | Year | Males | Females |
|-----|------|-------|---------|
| 1   | 1629 | 5218  | 4683    |
| 2   | 1630 | 4858  | 4457    |
| 3   | 1631 | 4422  | 4102    |
| 4   | 1632 | 4994  | 4590    |
| 5   | 1633 | 5158  | 4839    |
| 6   | 1634 | 5035  | 4820    |
| ... | ...  | ...   | ...     |

This table is wide form because "Males" and "Females" are two columns both
measuring number of births. Wide form data can always be transformed to long
form (e.g. with the `stack` function in DataFrames) but this can be
inconvenient, especially if the data is not already in a DataFrame.

```julia
stack(births, [:Males, :Females])
```

| Row | variable | value | Year |
|-----|----------|-------|------|
| 1   | Males    | 5218  | 1629 |
| 2   | Males    | 4858  | 1630 |
| 3   | Males    | 4422  | 1631 |
| ... | ...      | ...   | ...  |
| 162 | Females  | 7623  | 1708 |
| 163 | Females  | 7380  | 1709 |
| 164 | Females  | 7288  | 1710 |

The resulting table is long form with number of births in one column, here
with the default name given by `stack`: "value". Data in this form can be
plotted very conveniently with Gadfly.

```@setup 2
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)
```

```@example 2
births = RDatasets.dataset("HistData", "Arbuthnot")[:,[:Year, :Males, :Females]] # hide
plot(stack(births, [:Males, :Females]), x=:Year, y=:value, color=:variable,
     Geom.line)
```

In some cases, explicitly transforming the data can be burdensome. Gadfly
lets you avoid this by referring to columns or groups of columns in an
implicit long-form version of the data.

```@example 2
plot(births, x=:Year, y=Col.value(:Males, :Females),
     color=Col.index(:Males, :Females), Geom.line)
nothing # hide
```

Here `Col.value` produces the concatenated values from a set of columns, and
`Col.index` refers to a vector labeling each value in that concatenation by
the column it came from. Also useful is `Row.index`, which will give the row
index of items in a concatenation.

This syntax also lets us more conveniently plot data that is not in a
DataFrame, such as matrices or arrays of arrays. Below we recreate the plot
above for a third time after first converting the DataFrame to an Array.

```@example 2
births_array = convert(Matrix{Int}, births)
plot(births_array, x=Col.value(1), y=Col.value(2:3...),
     color=Col.index(2:3...), Geom.line, Scale.color_discrete,
     Guide.colorkey(labels=["Males","Females"]), Guide.xlabel("Year"))
nothing # hide
```

When given no arguments `Row.index`, `Col.index`, and `Col.value` assume all
columns are being concatenated.

Plotting arrays of vectors works in much the same way as matrices, but
constituent vectors may be of varying lengths.
