# A Brief Demonstration of Gadfly

Gadfly is an implementation of a "grammar of graphics" style statistical
graphics system for Julia. Though currently far from complete, some basics are
up and running. This document will show some examples of what currently works
while giving you a feel for the overall system.

To begin, we need some data. The data Gadfly plots is always given in the form
of a DataFrame. We'll pick and choose some examples from the RDatasets packages.

Fisher's iris data set is a good starting point.

```julia
load("Gadfly")
using Gadfly

load("RDatasets")
using RDatasets

iris = data("datasets", "iris")
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

```julia
p = plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width"}, Geom.point)
```

This produces a `Plot` object. We can turn it into a graphic by calling `render`
on it, and this can then in turn be drawn on one or more backends.

```julia
g = render(p)

img = SVG("iris_plot.svg", 6inch, 4inch)
draw(img, g)
finish(img)
```

Now we have the following charming little SVG image.

![Iris Plot 1](http://dcjones.github.com/gadfly/iris1.svg)

For the rest of the demonstrations, we'll omit the `render` and `draw` calls for
brevity.

In this plot we've mapped the x aesthetic to the `Sepal.Length` column and the y
aesthetic to the `Sepal.Width`. The last argument, `Geom.point`, is a geometry
element which takes bound aesthetics and render delightful figures. Adding other
geometries produces layers, which may or may not result in a coherent plot.

```julia
p = plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width"},
         Geom.point, Geom.line)
```

![Iris Plot 2](http://dcjones.github.com/gadfly/iris2.svg)

This is the grammar of graphics equivalent of "colorless green ideas sleep
furiously". It is valid grammar, but not particularly meaningful.

### Color

Let's do add something meaningful by mapping the color aesthetic.

```julia
p = plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width", :color => "Species"},
         Geom.point)
```

![Iris Plot 3](http://dcjones.github.com/gadfly/iris3.svg)

Ah, a scientific discovery: Setosa has short but wide sepals!

Color scales in Gadfly by default are produced from perceptually uniform
colorspaces (LUV/LCHuv or LAB/LCHab), though it supports RGB, HSV, HLS, XYZ, and
converts arbitrarily between these. Of course, CSS/X11 named colors work too:
"old lace", anyone?

### Scale transforms

Scale transforms also work as expected. Let's look at some data where this is
useful.

```julia
mammals = data("MASS", "mammals")
p = plot(mammals, {:x => "body", :y => "brain"}, Geom.point)
```

![Mammal Plot 1](http://dcjones.github.com/gadfly/mammals1.svg)

This is no good, the whales are ruining things for us. Putting both axis on a
log-scale clears things up.

```julia
p = plot(mammals, {:x => "body", :y => "brain"},
         Geom.point, Scale.x_log10, Scale.y_log10)
```

![Mammal Plot 2](http://dcjones.github.com/gadfly/mammals2.svg)

### Discrete scales

Since all continuous analysis is just degenerate discrete analysis, let's take a
crack at the latter using some fuel efficiency data.

```julia
gasoline = data("Ecdat", "Gasoline")

p = plot(gasoline, {:x => "year", :y => "lgaspcar", :color => "country"},
         Geom.point, Geom.line)

# Make this image wider so the axis labels fit
g = render(p)
img = SVG("gasoline_plot.svg", 9inch, 4inch)
draw(img, g)
finish(img)
```

![Gasoline Plot 1](http://dcjones.github.com/gadfly/gasoline1.svg)

We could have added `Scale.x_discrete` explicitly, but this is detected and the
right default is chosen. This is the case with most of elements in the grammar:
we've omitted `Scale.x_continuous` and `Scale.y_continuous` in the previous
plots, as well as `Coord.cartesian`, and guide elements such as
`Guide.color_key`, `Guide.x_ticks`, `Guide.XLabel`, and so on. As much as
possible the system tries to fill in the gaps with reasonable defaults.

### Rendering

Gadfly uses a custom graphics library called Compose, which is an attempt at a
more elegant, purely functional take on the R `grid` package. It allows mixing
of absolute and relative units and complex coordinate transforms. The primary
backend is a native SVG generator (almost native: it uses pango to precompute
text extents), though there is also a (currently, slightly buggy) Cairo backend.

Building graphics declaratively let's you do some fun things. Like stick to
plots together:

```julia
fig1a = render(plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width"},
                    Geom.point))
fig1b = render(plot(iris, {:x => "Sepal.Width"}, Geom.bar))
fig1 = hstack(fig1a, fig1b)

img = SVG("fig1.svg", 9inch, 4inch)
draw(img, fig1)
finish(img)
```

![Fig1](http://dcjones.github.com/gadfly/fig1.svg)

Ultimately this will make more complex visualizations easier to build. For
example, facets, plots within plots, and so on.

### Interactivity

One advantage of generating our own SVG is that the files are much more
compact than those produced by Cairo, by virtue of having a higher level API.
Another advantage is that we can annotate our SVG output and embed javascript
code to provide some level of dynamism.

As a proof of concept, color keys support toggling categories on and off by
clicking the category name. Javascript is disabled in GitHub rendered markdown
files, but works by viewing one the figures [directly](gasoline1.svg).

Though not a replacement for full-fledged custom interactive visualizations of
the sort produced by d3, this sort of mild interactivity can improve a lot of
standard plots. The fuel efficiency plot is made more clear by toggling off some
of the countries, for example.


