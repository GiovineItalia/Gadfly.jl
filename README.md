!["Alice looked up at the Rocking-horse-fly with great interest, and made up her
mind that it must have been just repainted, it looked so bright and sticky."](http://dcjones.github.com/Gadfly.jl/rockinghorsefly.png)

Julia 0.3 [![Gadfly](http://pkg.julialang.org/badges/Gadfly_release.svg)](http://pkg.julialang.org/?pkg=Gadfly&ver=release)

Julia 0.4 [![Gadfly](http://pkg.julialang.org/badges/Gadfly_nightly.svg)](http://pkg.julialang.org/?pkg=Gadfly&ver=nightly)

[![DOI](https://zenodo.org/badge/6322/dcjones/Gadfly.jl.png)](http://dx.doi.org/10.5281/zenodo.11876) [![Build Status](http://img.shields.io/travis/dcjones/Gadfly.jl.svg)](https://travis-ci.org/dcjones/Gadfly.jl) [![Coverage Status](http://img.shields.io/coveralls/dcjones/Gadfly.jl.svg)](https://coveralls.io/r/dcjones/Gadfly.jl)

**Gadfly** is a plotting and data visualization system written in
[Julia](http://julialang.org/).

It's influenced heavily by Leland Wilkinson's book
[The Grammar of Graphics](http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html)
and Hadley Wickham's refinment of that grammar in
[ggplot2](http://ggplot2.org/).

It renders publication quality graphics to PNG, Postscript, PDF, SVG. The SVG
backend uses embedded javascript, powered by [Snap.svg](http://snapsvg.io/) to
add interactivity like panning, zooming, and toggling.

Check out the [manual](http://gadflyjl.org) for more details and
examples.

# Installation
[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/dcjones/Gadfly.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

From the Julia REPL a reasonably up to date version can be installed with

```julia
Pkg.add("Gadfly")
```

This will likely result in two dozen or so other packages also being
installed.

## Optional: cairo, pango, and fontconfig

Gadfly works best with the C libraries cairo, pango, and fontconfig installed.
The PNG, PS, and PDF backends require cairo, but without it the SVG backends
(`SVG` and `SVGJS`) are still available.

Complex layouts involving text are also somewhat more accurate when pango and
fontconfig are available.

Julia's Cairo bindings can be installed with

```julia
Pkg.add("Cairo")
```

# Three Invocations

All interaction with Gadfly is through the `plot` function, which takes three
major forms.


## Orthodox

```julia
plot(data::AbstractDataFrame, elements::Element...; mapping...)
```

This form is the standard "grammar of graphics" method of plotting. Data is
supplied in the form of a
[dataframe](https://github.com/juliastats/dataframes.jl), columns of the data
are bound to *aesthetics*, and plot elements including **scales**,
**coordinates**, **statistics**, **guides**, and **geometries** are added to the
plot.

All of the examples that follow will be plotting data from
[RDatasets](https://github.com/johnmyleswhite/RDatasets.jl).

To render these plots to a file, call `draw` on the resulting plot.

```julia
draw(SVG("myplot.svg", 6inch, 3inch), plot(...))
```

A few examples now.


```julia
# E.g.
plot(dataset("datasets", "iris"),x="SepalLength", y="SepalWidth", Geom.point)
```

![Iris](http://homes.cs.washington.edu/~dcjones/gadfly/iris.svg)

```julia
# E.g.
plot(dataset("car", "SLID"), x="Wages", color="Language", Geom.histogram)
```

![Car](http://homes.cs.washington.edu/~dcjones/gadfly/car.svg)

A catalog of plot elements given later in this document.


## Heretical

```julia
plot(elements::Element...; mapping...)
```

Along with the orthodox invocation of `plot`, some relaxed invocations of the
grammar exist as a "slang of graphics". This form of `plot` omits the the data
frame. Instead, plain old arrays are bound to aesthetics.

```julia
# E.g.
plot(x=collect(1:100), y=sort(rand(100)))
```

![Points](http://homes.cs.washington.edu/~dcjones/gadfly/points.svg)

If no geometry is specified, like in the example above, a `Geom.point` is stuck
into your plot.

This `plot` otherwise works the same. We might want to name these axis, for
example.

```julia
# E.g.
plot(x=collect(1:100), y=sort(rand(100)),
     Guide.XLabel("Index"), Guide.YLabel("Step"))
```

![Labeled_points](http://homes.cs.washington.edu/~dcjones/gadfly/labeled_points.svg)


## Functions and Expressions

```julia
plot(f::Function, a, b, elements::Element...)

plot(fs::Array, a, b, elements::Element...)
```

Some special forms of `plot` exist for quickly generating 2d plots of functions.

```julia
# E.g.
plot([sin, cos], 0, 25)
```

![Sin/Cos](http://homes.cs.washington.edu/~dcjones/gadfly/sin_cos.svg)


# Elements

Plot elements in Gadfly are statistics, scales, geometries, and guides. Each
operates on data bound to aesthetics, but in different ways.

### Statistics

Statistics are functions taking as input one or more aesthetics, operating on
those values, then output to one or more aesthetic. For example, drawing of
boxplots typically uses the boxplot statistic (Stat.boxplot) that takes as input
the `x` and `y` aesthetic, and outputs the middle, and upper and lower hinge,
and upper and lower fence aesthetics.

### Scales

Scales, similarly to statistics apply a transformation to the original data,
typically mapping one aesthetic to the same aesthetic, while retaining the
original value. The `Scale.x_log10` aesthetic maps the `x` aesthetic back the
`x` aesthetic after applying a log10 transformation, but keeps track of the
original value so that data points are properly identified.

### Geometries

Finally geometries are responsible for actually doing the drawing. A geometry
takes as input one or aesthetics, and used data bound to these aesthetics to
draw things. The `Geom.point` geometry draws points using the `x` and `y`
aesthetics, the `Geom.line` geometry draws lines, and so on.

### Guides

Very similar to geometries are guides, which draw graphics supported the actual
visualization, such as axis ticks and labels and color keys. The major
distinction is that geometries always draw within the rectangular plot frame,
while guides have some special layout considerations.

# Drawing to backends

Gadfly plots can be rendered to number of formats. Without cairo, or any
non-julia libraries, it can produce SVG. Installing cairo gives you access to
the `PNG`, `PDF`, and `PS` backends. Rendering to a backend works the same for
any of these.

```julia
some_plot = plot(x=[1,2,3], y=[4,5,6])
draw(PNG("myplot.png", 6inch, 3inch), some_plot)
```

## Using the SVGJS backend

The `SVGJS` backend writes SVG with embedded javascript. There are a couple
subtlties with using the output from this backend.

Drawing to the backend works like any other.

```julia
draw(SVGJS("mammals.js.svg", 6inch, 6inch), p)
```

If included with an `<img>` tag, it will display as a static SVG image.
```html
<img src="mammals.js.svg"/>
```

For the interactive javascript features to be enables, the output either needs
to be inluded inline in the HTML page, or include with an object tag, like.

```html
<object data="mammals.js.svg" type="image/svg+xml"></object>
```

# Reporting Bugs

This is a new and fairly complex piece of software. [Filing an
issue](https://github.com/dcjones/Gadfly.jl/issues/new) to report a bug,
counterintuitive behavior, or even to request a feature is extremely valuable in
helping me prioritize what to work on, so don't hestitate.


