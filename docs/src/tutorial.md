```@meta
Author = "Tamas Nagy, Daniel C. Jones, Simon Leblanc"
```

# Tutorial

Gadfly is an implementation of a "grammar of graphics" style statistical
graphics system for Julia. This tutorial will outline general usage
patterns and will give you a feel for the overall system.

To begin, we need some data. Gadfly works best when the data is supplied
in a [DataFrame](https://juliastats.github.io/DataFrames.jl/stable/). In
this tutorial, we'll pick and choose some examples from the
[RDatasets](https://github.com/johnmyleswhite/RDatasets.jl) package.

Let us use Fisher's iris dataset as a starting point.

```@example 1
using Gadfly
using RDatasets

iris = dataset("datasets", "iris")
nothing # hide
```

The `plot` function in Gadfly is of the form:

```julia
plot(data::DataFrame, mapping::Dict, elements::Element...)
```

The first argument is the data to be plotted, the second is a dictionary
mapping "aesthetics" to columns in the data frame, and this is followed by some
number of elements, which are the nouns and verbs, so to speak, that form the
grammar.

Let's get to it.

```@example 1
p = plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point)
nothing # hide
```

This produces a `Plot` object. It can be drawn on one or more backends using `draw`.

```julia
img = SVG("iris_plot.svg", 6inch, 4inch)
draw(img, p)
```

Now we have the following charming little SVG image.

```@example 1
p # hide
```

For the rest of the demonstrations, we'll omit the `draw` call for
brevity.

In this plot we've mapped the x aesthetic to the `SepalLength` column and
the y aesthetic to the `SepalWidth`. The last argument,
[Geom.point](@ref), is a geometry element which takes bound aesthetics and
render delightful figures. Adding other geometries produces layers, which
may or may not result in a coherent plot.

```@example 1
p = plot(iris, x=:SepalLength, y=:SepalWidth,
         Geom.point, Geom.line)
```

This is the grammar of graphics equivalent of "colorless green ideas sleep
furiously". It is valid grammar, but not particularly meaningful.

## Color

Let's do add something meaningful by mapping the color aesthetic.

```@example 1
p = plot(iris, x=:SepalLength, y=:SepalWidth, color=:Species,
         Geom.point)
```

Ah, a scientific discovery: Setosa has short but wide sepals!

Color scales in Gadfly by default are produced from perceptually uniform
colorspaces (LUV/LCHuv or LAB/LCHab), though it supports RGB, HSV, HLS, XYZ, and
converts arbitrarily between these. Of course, CSS/X11 named colors work too:
"old lace", anyone?

## Scale transforms

Scale transforms also work as expected. Let's look at some data where this is
useful.

```@example 1
mammals = dataset("MASS", "mammals")
p = plot(mammals, x=:Body, y=:Brain, label=:Mammal, Geom.point, Geom.label)
```

This is no good, the large animals are ruining things for us. Putting both
axis on a log-scale clears things up.

```@example 1
p = plot(mammals, x=:Body, y=:Brain, label=:Mammal,
         Geom.point, Geom.label, Scale.x_log10, Scale.y_log10)
```

## Discrete scales

Since all continuous analysis is just degenerate discrete analysis, let's take a
crack at the latter using some fuel efficiency data.

```@example 1
gasoline = dataset("Ecdat", "Gasoline")

p = plot(gasoline, x=:Year, y=:LGasPCar, color=:Country,
         Geom.point, Geom.line)
```

We could have added [Scale.x_discrete](@ref) explicitly, but this is
detected and the right default is chosen. This is the case with most of
elements in the grammar: we've omitted [Scale.x_continuous](@ref) and
[Scale.y_continuous](@ref) in the previous plots, as well as
[Coord.cartesian](@ref), and guide elements such as [Guide.xticks](@ref),
[Guide.xlabel](@ref), and so on. As much as possible the system tries to fill in
the gaps with reasonable defaults.

## Rendering

Gadfly uses a custom graphics library called
[Compose](https://github.com/GiovineItalia/Compose.jl), which is an attempt at a
more elegant, purely functional take on the R `grid` package. It allows
mixing of absolute and relative units and complex coordinate transforms.
The primary backend is a native SVG generator (almost native: it uses
pango to precompute text extents), though there is also a Cairo backend.
See [Backends](@ref) for more details.

Building graphics declaratively let's you do some fun things. Like stick two
plots together:

```@example 1
fig1a = plot(iris, x="SepalLength", y="SepalWidth", Geom.point)
fig1b = plot(iris, x="SepalWidth", Geom.bar)
fig1 = hstack(fig1a, fig1b)
```

Ultimately this will make more complex visualizations easier to build. For
example, facets, plots within plots, and so on. See [Stacks and
Layers](@ref) for more details.

## Interactivity

One advantage of generating our own SVG is that the files are much more
compact than those produced by Cairo, by virtue of having a higher level API.
Another advantage is that we can annotate our SVG output and embed Javascript
code to provide some level of dynamism.

Though not a replacement for full-fledged custom interactive visualizations of
the sort produced by d3, this sort of mild interactivity can improve a lot of
standard plots. The fuel efficiency plot is made more clear by toggling off some
of the countries, for example.
