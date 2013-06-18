
Gadfly is a system for plotting and visualization based largely on Hadley
Wickhams's [ggplot2](http://ggplot2.org/) for R, and Leland Wilkinson's book
[The Grammar of Graphics](http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html).

This document will go through a few examples of plotting in Gadfly.

## Installation

Gadfly can be installed from the Julia repl quite easily.

```{.julia execute="false"}
Pkg.add("Gadfly")
```

## Executing this document

The markdown version of this document (`doc/overview.md`) is executable,
generating all the figures and producing an HTML file. This is a good way to
check that your install of Gadfly works as advertised. To execute it, you will
need to have [Pandoc](http://johnmacfarlane.net/pandoc/) installed, then in the
`doc` directory and type:

```{.bash execute="false"}
../bin/gadfly overview.md > overview.html
```

You should have a file called `overview.html` and a bunch of svg figures. If
not, feel free to file a bug report.

Writing your own executable markdown file is very simple. If you're curious, have
a peek at the raw markdown version of this document.


## Simple plots

(It is assumed that you will be running all of the following commands in the
same Julia session.)

We'll need some data to plot. Plotting is primarily performed on DataFrame
objects. The RDatasets packages has a treasure trove of examples we can use.

```{.julia}
using RDatasets
```

Fisher's measurements on irises is a good first data set.

```{.julia}
using Gadfly
using Compose

iris = data("datasets", "iris")

p = plot(iris,
         x="Sepal.Length", y="Sepal.Width",
         Geom.point)
draw(D3(6inch, 4inch), p)
```

The `plot` function in Gadfly is of the form:

```{.julia execute="false"}
plot(data::DataFrame, mapping::Dict, elements::Element...)
```

The first argument is the data to be plotted, the second is a dictionary
mapping "aesthetics" to columns in the data frame, and this is followed by some
number of elements, which are the nouns and verbs, so to speak, that form the
grammar.

Note that for these examples we will be drawing on an D3 backend that inserts
the graphic directly into the document. Gadfly can render to a number of
backends. To generate an SVG image file, use something like:
`SVG("iris_plot.svg", 6inch, 4inch)`

## Aesthetics

Every geometry has some set of required and optional aesthetics. The point
geometry requires that `x` and `y` be mapped, and has the optional aesthetic
`color` which will group points categorically indicated by color.

```{.julia}
p = plot(iris,
         x="Sepal.Length", y="Sepal.Width", color="Species",
         Geom.point)
draw(D3(6inch, 4inch), p)
```

## Scale Transformations

Scale transforms also work as expected. Let's look at some data where this is
useful.

```{.julia}
mammals = data("MASS", "mammals")

p = plot(mammals,
         x="body", y="brain",
         Geom.point)
draw(D3(6inch, 6inch), p)
```

This is no good, the elephants are ruining things for us. Putting both axis on a
log-scale clears things up.

```{.julia}
p = plot(mammals,
         x="body", y="brain",
         Geom.point, Scale.x_log10, Scale.y_log10)
draw(D3(6inch, 6inch), p)
```

## Labels

The label geometry places maps data to text labels placed near the position
indicated by the x and y aesthetics. It solves an optimization problem to try to
position the labels such that none overlap or are plotted out of bounds. By
default, labels that cannot be plotted without overlapping are hidden.

Let's label that previous plot.

```{.julia}
p = plot(mammals,
         x="body", y="brain", label=1,
         Geom.label, Geom.point, Scale.x_log10, Scale.y_log10)
draw(D3(6inch, 6inch), p)
```

Mapping `label` to 1, gives the first column of the data frame, which is not
named, but contains the species that each measurement was made on.


## Histograms

The bar geometry applies the `Stat.histogram` statistic by default, producing a
histogram.

```{.julia}
using Distributions
using DataFrames

normmix = MixtureModel([Normal(-3, 1), Normal(3, 1)], [0.7, 0.3])
xs = DataFrame({"x" => Float64[rand(normmix) for _ in 1:5000]})

p = plot(xs,
         x="x",
         Geom.bar)
draw(D3(4inch, 3inch), p)
```

No need to specify the number of bins, if not given a reasonable number is
chosen using a penalized maximum likelihood procedure.


## 2D Histograms / Heat maps

Histograms in two-dimensions can be drawn with Geom.rectbin.

```{.julia}
d = MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0])
xys = [rand(d) for _ in 1:5000]
xs = Float64[xy[1] for xy in xys]
ys = Float64[xy[2] for xy in xys]

p = plot(DataFrame({"x" => xs, "y" => ys}),
                   x="x", y="y",
                   Geom.rectbin)

draw(D3(5inch, 4inch), p)
```


## Boxplots

The boxplot geometry shows the distribution of the y aesthetic, grouped by the x
aesthetic. Here is a (log) wage distribution categorized by years of education.

```{.julia}
wages = data("plm", "Wages")
p = plot(wages,
         x="ed",
         y="lwage",
         Geom.boxplot)
draw(D3(4inch, 4inch), p)
```


## Plotting functions

Though Gadfly primarily plots data frames, there are convenience functions to do
simple function plotting.

```{.julia}
p = plot([sin, cos], 0, 25)
draw(D3(6inch, 3inch), p)
```

This form of `plot` takes one or more functions, followed by a lower and upper
bounds over which the function will be plotted.


## Interactivity

The D3 backend generates javascript files containing code to that generates an SVG
mage. It looks very much like images produced by the SVG backend, but leverages
d3 to adds some simple interactivity. Plots can panned (by dragging) and zoomed
(using the scroll wheel), and color keys can be clicked to toggle groups on and
off.

The d3 backend is very new, so expect a few glitches and look forward to much
more on this front.

## Compose

Gadfly is based on a declarative vector graphics system called
[Compose](https://github.com/dcjones/Compose.jl). This let's one do interesting
things with plots, once they are defined.

```{.julia}
fig1a = plot(iris, x="Sepal.Length", y="Sepal.Width", Geom.point)
fig1b = plot(iris, x="Sepal.Width", Geom.bar)
fig1 = hstack(fig1a, fig1b)

draw(D3(6inch, 3inch), fig1)
```

Ultimately Compose will allow the creation of more complex plots, such as those
containing facets, or plots within plots.

