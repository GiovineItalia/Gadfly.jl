```@meta
Author = "Daniel C. Jones"
```

# Plotting

Most interaction with Gadfly is through the `plot` function. Plots are described
by binding data to **aesthetics**, and specifying a number of plot elements
including [Scales](@ref), [Coordinates](@ref), [Guides](@ref), and [Geometries](@ref).
Aesthetics are a set of special named variables that are mapped to plot
geometry. How this mapping occurs is defined by the plot elements.

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

![](plot-arrays-1.svg)

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
