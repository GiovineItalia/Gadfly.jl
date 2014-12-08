---
title: Introduction
author: Daniel Jones
order: 1
...

<div style="text-align: center"><img width=300px src="logo.svg"></div>

Gadfly is a system for plotting and visualization based largely on Hadley
Wickhams's [ggplot2](http://ggplot2.org/) for R, and Leland Wilkinson's book
[The Grammar of Graphics](http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html).

# Getting Started

From the Julia REPL a reasonably up to date version can be installed with

```{.julia execute="false"}
Pkg.add("Gadfly")
```

This will likely result in half a dozen or so other packages also being
installed.

Gadfly is then loaded with.

```{.julia results="none"}
using Gadfly
```

```{.julia hide="true" results="none"}
Gadfly.set_default_plot_size(14cm, 8cm)
```

## Optional: cairo, pango, and fontconfig

Gadfly works best with the C libraries cairo, pango, and fontconfig installed.
The PNG, PS, and PDF backends require cairo, but without it the SVG backends
(`SVG` and `SVGJS`) are still available.

Complex layouts involving text are also somewhat more accurate when pango and
fontconfig are available.

Julia's Cairo bindings can be installed with

```{.julia execute="false"}
Pkg.add("Cairo")
```

# Plot invocations

Most interaction with Gadfly is through the `plot` function. Plots are described
by binding data to **aesthetics**, and specifying a number of plot elements
including **scales**, **coordinates**, **guides**, and **geometries**.
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

```{.julia hide="true"}
srand(12345)
```

```julia
# E.g.
plot(x=rand(10), y=rand(10))
```

Multiple elements can use the same aesthetics to produce different output. Here
the point and line geometries act on the same data and their results are
layered.

```julia
# E.g.
plot(x=rand(10), y=rand(10), Geom.point, Geom.line)
```

More complex plots can be produced by combining elements.

```julia
# E.g.
plot(x=1:10, y=2.^rand(10),
     Scale.y_sqrt, Geom.point, Geom.smooth,
     Guide.xlabel("Stimulus"), Guide.ylabel("Response"), Guide.title("Dog Training"))
```

To generate an image file from a plot, use the `draw` function. Gadfly supports
a number of drawing backends. Each is used similarly.

```{.julia execute="false"}
# define a plot
myplot = plot(..)

# draw on every available backend
draw(SVG("myplot.svg", 4inch, 3inch), myplot)
draw(SVGJS("myplot.svg", 4inch, 3inch), myplot)
draw(PNG("myplot.png", 4inch, 3inch), myplot)
draw(PDF("myplot.pdf", 4inch, 3inch), myplot)
draw(PS("myplot.ps", 4inch, 3inch), myplot)
```

If used from [IJulia](https://github.com/JuliaLang/IJulia.jl), the output of
`plot` will be shown automatically.

## Plotting data frames

The [DataFrames](https://github.com/JuliaStats/DataFrames.jl) package provides a
powerful means of representing and manipulating tabular data. They can be used
directly in Gadfly to make more complex plots simpler and easier to generate.

In this form of `plot`, a data frame is passed to as the first argument, and
columns of the data frame are bound to aesthetics by name or index.

```{.julia execute="false"}
# Signature for the plot applied to a data frames.
plot(data::AbstractDataFrame, elements::Element...; mapping...)
```

The [RDatasets](https://github.com/johnmyleswhite/RDatasets.jl) package collects
example data sets from R packages. We'll use that here to generate some example
plots on realistic data sets. An example data set is loaded into a data frame
usinge the `data` function.


```julia
using RDatasets
```

```julia
# E.g.
plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point)
```

```julia
# E.g.
plot(dataset("car", "SLID"), x="Wages", color="Language", Geom.histogram)
```

Along with less typing, using data frames to generate plots allows the axis and
guide labels to be set automatically.


## Functions and Expressions

Along with the standard plot function, Gadfly has some special forms to make
plotting functions and expressions more convenient.

```{.julia execute="false"}
plot(f::Function, a, b, elements::Element...)

plot(fs::Array, a, b, elements::Element...)
```

Some special forms of `plot` exist for quickly generating 2d plots of functions.

```julia
# E.g.
plot([sin, cos], 0, 25)
```

# Layers

<!--TODO: Expand the shit out of this. There should be whole page on layers.-->

Gadfly can draw multiple layers to the same plot:

```{.julia execute="false"}
plot(layer(x=rand(10), y=rand(10), Geom.point),
     layer(x=rand(10), y=rand(10), Geom.line))
```


Or if your data is in a DataFrame:

```{.julia execute="false"}
plot(my_data, layer(x="some_column1", y="some_column2", Geom.point),
              layer(x="some_column3", y="some_column4", Geom.line))
```

You can also pass different data frames to each layers:
```{.julia execute="false"}
layer(another_dataframe, x="col1", y="col2", Geom.point)
```

# Stacking

Plots can also be stacked horizontally with ``hstack`` or vertically with ``vstack``. This allows more customization in regards to tick marks, axis labeling, and other plot details than is available with ``subplot_grid``.

```{.julia execute="false"}
p1 = plot(x=[1,2,3], y=[4,5,6])
p2 = plot(x=[1,2,3], y=[6,7,8])
draw(PDF("p1and2.pdf", 6inch, 6inch), vstack(p1,p2))
p3 = plot(x=[5,7,8], y=[8,9,10])
p4 = plot(x=[5,7,8], y=[10,11,12])
draw(PDF("p1to4.pdf", 6inch, 9inch), vstack(hstack(p1,p2),hstack(p3,p4)))
```

# Drawing to backends

Gadfly plots can be rendered to number of formats. Without cairo, or any
non-julia libraries, it can produce SVG. Installing cairo gives you access to
the `PNG`, `PDF`, and `PS` backends. Rendering to a backend works the same for
any of these.

```{.julia execute="false"}
p = plot(x=[1,2,3], y=[4,5,6])
draw(PNG("myplot.png", 12cm, 6cm), p)
```

## Using the SVGJS backend

The `SVGJS` backend writes SVG with embedded javascript. There are a couple
subtlties with using the output from this backend.

Drawing to the backend works like any other.

```{.julia execute="false"}
draw(SVGJS("mammals.js.svg", 6inch, 6inch), p)
```

If included with an `<img>` tag, it will display as a static SVG image.
```{.html execute="false"}
<img src="mammals.js.svg"/>
```

For the interactive javascript features to be enables, the output either needs
to be inluded inline in the HTML page, or include with an object tag, like.

```{.html execute="false"}
<object data="mammals.js.svg" type="image/svg+xml"></object>
```

A `div` element must be placed, and the `draw` function defined in mammals.js
must be passed the id of this element, so it knows where in the document to
place the plot.

# IJulia

The [IJulia](https://github.com/JuliaLang/IJulia.jl) project adds Julia support
to [IPython](http://ipython.org/). This includes a browser based notebook that
can inline graphics and plots. Gadfly works out of the box with IJulia, with or
without drawing explicity to a backend.

Without a specific call to `draw` (i.e. just calling `plot`), the D3 backend is
used with a default plot size. The default plot size can be changed with
`set_default_plot_size`.

```{.julia execute="false"}
# E.g.
set_default_plot_size(12cm, 8cm)
```

# Reporting Bugs

This is a new and fairly complex piece of software. [Filing an
issue](https://github.com/dcjones/Gadfly.jl/issues/new) to report a bug,
counterintuitive behavior, or even to request a feature is extremely valuable in
helping me prioritize what to work on, so don't hestitate.




