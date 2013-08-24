---
title: Introduction
author: Daniel Jones
order: 1
...

![](breadandbutterfly.jpg)

Gadfly is a system for plotting and visualization based largely on Hadley
Wickhams's [ggplot2](http://ggplot2.org/) for R, and Leland Wilkinson's book
[The Grammar of Graphics](http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html).

# Getting Started

From the Julia REPL a reasonably up to data version can be installed with

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
Gadfly.prepare_display()
Gadfly.set_default_plot_size(14cm, 8cm)
```

## Optional: cairo, pango, and fontconfig

Gadfly works best with the C libraries cairo, pango, and fontconfig installed.
The PNG, PS, and PDF backends require cairo, but without it the SVG and
Javascript/D3 backends are still available.

Complex layouts involving text are also somewhat more accurate when pango and
fontconfig are available.

Julia's Cairo bindings can be installed with

```{.julia execute="false"}
Pkg.add("Cairo")
```


# The Three Invocations of Plot

All interaction with Gadfly is through the `plot` function, which takes three
major forms.

## Orthodox

```{.julia execute="false"}
plot(data::AbstractDataFrame, elements::Element...; mapping...)
```

This form is the standard "grammar of graphics" method of plotting. data is
supplied in the form of a
[dataframe](https://github.com/juliastats/dataframes.jl), columns of the data
are bound to *aesthetics*, and plot elements including **scales**,
**coordinates**, **statistics**, **guides**, and **geometries** are added to the
plot.

To render these plots to a file, call `draw` on the resulting plot.

```{.julia execute="false"}
# E.g.
draw(SVG("myplot.svg", 6inch, 3inch), plot(...))
draw(PNG("myplot.png", 6inch, 3inch), plot(...))
draw(D3("myplot.js", 6inch, 3inch), plot(...))
```

A few examples now. All of the samples that follow will be plotting data from
[RDatasets](https://github.com/johnmyleswhite/RDatasets.jl).

```julia
using RDatasets
```


```julia
# E.g.
plot(data("datasets", "iris"), x="Sepal.Length", y="Sepal.Width", Geom.point)
```

```julia
# E.g.
plot(data("car", "SLID"), x="wages", color="language", Geom.histogram)
```

## Heretical

```{.julia execute="false"}
plot(elements::Element...; mapping...)
```

Along with the orthodox invocation of `plot`, some relaxed invocations of the
grammar exist as a "slang of graphics". This form of `plot` omits the the data
frame. Instead, plain old arrays are bound to aesthetics.


## Functions and Expressions


```{.julia execute="false"}
plot(f::Function, a, b, elements::Element...)

plot(fs::Array, a, b, elements::Element...)

@plot(expr, a, b)
```

Some special forms of `plot` exist for quickly generating 2d plots of functions.

```julia
# E.g.
plot([sin, cos], 0, 25)
```

```julia
# E.g.
@plot(cos(x)/x, 5, 25)
```

# Drawing to backends

Gadfly plots can be rendered to number of formats. Without cairo, or any
non-julia libraries, it can produce SVG and d3-powered javascript. Installing
cairo gives you access to the `PNG`, `PDF`, and `PS` backends. Rendering to a
backend works the same for any of these.

```{.julia execute="false"}
p = plot(x=[1,2,3], y=[4,5,6])
draw(PNG("myplot.png", 12cm, 6cm), p)
```

## Using the d3 backend

The `D3` backend writes javascript. Making use of it's output is slightly more
involved than with the image backends.

Rendering to Javascript is easy enough:

```{.julia execute="false"}
draw(D3("plot.js", 6inch, 6inch), p)
```

Before the output can be included, you must include the d3 and gadfly javascript
libraries. The necessary include for Gadfly is "gadfly.js" which lives in the
src directory (which you can find by running `joinpath(Pkg.dir("Gadfly"), "src",
"gadfly.js")` in julia).

D3 can be downloaded from [here](http://d3js.org/d3.v3.zip).

Now the output can be included in an HTML like.

```{.html execute="false"}
<script src="d3.min.js"></script>
<script src="gadfly.js"></script>

<!-- Placed whereever you want the graphic to be rendered. -->
<div id="my_chart"></div>
<script src="mammals.js"></script>
<script>
draw("#my_chart");
</script>
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




