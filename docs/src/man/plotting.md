```@meta
Author = "Daniel C. Jones"
```

# Plotting

Most interaction with Gadfly is through the `plot` function. Plots are
described by binding data to **aesthetics**, and specifying a number of plot
elements including [Scales](@ref lib_scale), [Coordinates](@ref lib_coord),
[Guides](@ref lib_guide), and [Geometries](@ref lib_geom).  Aesthetics are a
set of special named variables that are mapped to plot geometry. How this
mapping occurs is defined by the plot elements.

This "grammar of graphics" approach tries to avoid arcane incantations and
special cases, instead approaching the problem as if one were drawing a wiring
diagram: data is connected to aesthetics, which act as input leads, and
elements, each self-contained with well-defined inputs and outputs, are
connected and combined to produce the desired result.


## Plotting arrays

If no plot elements are defined, point geometry is added by default. The point
geometry takes as input the `x` and `y` aesthetics. So all that's needed to draw
a scatterplot is to bind `x` and `y`.

```@setup 1
using Gadfly
srand(12345)
```

```@example 1
# E.g.
p = # hide
plot(x=rand(10), y=rand(10))
```

Multiple elements can use the same aesthetics to produce different output. Here
the point and line geometries act on the same data and their results are
layered.

```@example 1
# E.g.
plot(x=rand(10), y=rand(10), Geom.point, Geom.line)
```

More complex plots can be produced by combining elements.

```@example 1
# E.g.
plot(x=1:10, y=2.^rand(10),
     Scale.y_sqrt, Geom.point, Geom.smooth,
     Guide.xlabel("Stimulus"), Guide.ylabel("Response"), Guide.title("Dog Training"))
```

To generate an image file from a plot, use the `draw` function. Gadfly supports
a number of drawing [Backends](@ref).

## Plotting data frames

The [DataFrames](https://github.com/JuliaStats/DataFrames.jl) package provides a
powerful means of representing and manipulating tabular data. They can be used
directly in Gadfly to make more complex plots simpler and easier to generate.

In this form of `plot`, a data frame is passed to as the first argument, and
columns of the data frame are bound to aesthetics by name or index.

```julia
# Signature for the plot applied to a data frames.
plot(data::AbstractDataFrame, elements::Element...; mapping...)
```

The [RDatasets](https://github.com/johnmyleswhite/RDatasets.jl) package collects
example data sets from R packages. We'll use that here to generate some example
plots on realistic data sets. An example data set is loaded into a data frame
using the `dataset` function.


```@example 1
using RDatasets
```

```@example 1
# E.g.
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point)
```

```@example 1
# E.g.
plot(dataset("car", "SLID"), x="Wages", color="Language", Geom.histogram)
```

Along with less typing, using data frames to generate plots allows the axis and
guide labels to be set automatically.

## Functions and Expressions

Along with the standard plot function, Gadfly has some special forms to make
plotting functions and expressions more convenient.

```julia
plot(f::Function, a, b, elements::Element...)

plot(fs::Array, a, b, elements::Element...)
```

Some special forms of `plot` exist for quickly generating 2d plots of functions.

```@example 1
# E.g.
plot([sin, cos], 0, 25)
```

## Plotting wide-formatted data

Gadfly is designed to plot data is so-called "long form", in which data that
is of the same type, or measuring the same quantity, are stored in a single
column, and any factors or groups are specified by additional columns. This
is how data is typically stored in a database.

Sometimes data tables are organized by grouping values of the same type into
multiple columns, with a column name used to distinguish the grouping. We
refer to this as "wide form" data.

To illustrate the difference consider some historical London birth rate data.

```
births = RDatasets.dataset("HistData", "Arbuthnot")[[:Year, :Males, :Females]]
```

| Row | Year | Males | Females |
|-----|------|-------|---------|
| 1   | 1629 | 5218  | 4683    |
| 2   | 1630 | 4858  | 4457    |
| 3   | 1631 | 4422  | 4102    |
| 4   | 1632 | 4994  | 4590    |
| 5   | 1633 | 5158  | 4839    |
| 6   | 1634 | 5035  | 4820    |

This table is wide form because "Males" and "Females" are two columns both
measuring number of births. Wide form data can always be transformed to long
form, e.g. with the `stack` function in DataFrames, but this can be
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

The resulting table is long form with number of births in one columns, here
with the default name given by `stack`: "value". Data in this form can be
plotted very conveniently with Gadfly.

```@example 1
births = RDatasets.dataset("HistData", "Arbuthnot")[[:Year, :Males, :Females]] # hide
plot(stack(births, [:Males, :Females]), x=:Year, y=:value, color=:variable,
     Geom.line)
```

In some cases, explicitly transforming the data can be burdensome. Gadfly
lets you avoid this be referring to columns or groups of columns in a
implicit long-form version of the data.

```@example 1
plot(births, x=:Year, y=Col.value(:Males, :Females),
     color=Col.index(:Males, :Females), Geom.line)
```

Here `Col.value` produces the concatenated values from a set of columns, and
`Col.index` refers to a vector labeling each value in that concatenation by
the column it came from. Also useful is `Row.index`, which will give the row
index of items in a concatenation.

This syntax also lets us more conveniently plot data that is not in a
DataFrame, such as matrices or arrays of arrays. Here we plot each column of
a matrix as a separate line.

```@example 1
X = randn(40, 20) * diagm(1:20)
plot(X, x=Row.index, y=Col.value, color=Col.index, Geom.line)
```

When given no arguments `Row.index`, `Col.index`, and `Col.value` assume all
columns are being concatenated, but we could have equivalently used
`Col.index(1:20...)`, etc.

Plotting arrays of vectors works in much the same way as matrices, but
constituent vectors maybe be of varying lengths.

```@example 1
X = [randn(rand(10:20)) for _ in 1:10]
plot(X, x=Row.index, y=Col.value, color=Col.index, Geom.line)
```
