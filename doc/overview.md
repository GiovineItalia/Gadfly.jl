
# Introducing Gadfly

Gadfly is a system for plotting and visualization based largely on Hadley
Wickhams's [ggplot2](http://ggplot2.org/) for R, and Leland Wilkinson's book
[The Grammar of Graphics](http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html).

This document will give a quick overview of the current state of Gadfly's
development.

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
         {:x => "Sepal.Length", :y => "Sepal.Width"},
         Geom.point)
draw(SVG(6inch, 4inch), p)
```

The `plot` function in Gadfly is of the form:

```{.julia execute="false"}
plot(data::DataFrame, mapping::Dict, elements::Element...)
```

The first argument is the data to be plotted, the second is a dictionary
mapping "aesthetics" to columns in the data frame, and this is followed by some
number of elements, which are the nouns and verbs, so to speak, that form the
grammar.

Note that for these examples we will be drawing on an SVG backend that inserts
the graphic directly into the document. To generate these images individually,
you should include a file name: `SVG("iris_plot.svg", 6inch, 4inch)`

## Aesthetics

Every geometry has some set of required and optional aesthetics. The point
geometry requires that `:x` and `:y` be mapped, and has the optional aesthetic
`:color` which will group points categorically indicated by color.

```{.julia}
p = plot(iris,
         {:x => "Sepal.Length", :y => "Sepal.Width", :color => "Species"},
         Geom.point)
draw(SVG(6inch, 4inch), p)
```

## Scale Transformations

Scale transforms also work as expected. Let's look at some data where this is
useful.

```{.julia}
mammals = data("MASS", "mammals")

p = plot(mammals,
         {:x => "body", :y => "brain"},
         Geom.point)
draw(SVG(6inch, 6inch), p)
```

This is no good, the elephants are ruining things for us. Putting both axis on a
log-scale clears things up.

```{.julia}
p = plot(mammals,
         {:x => "body", :y => "brain"},
         Geom.point, Scale.x_log10, Scale.y_log10)
draw(SVG(6inch, 6inch), p)
```

## Labels

The label geometry places maps data to text labels placed near the position
indicated by the x and y aesthetics. It solves an optimization problem to try to
position the labels such that none overlap or are plotted out of bounds. By
default, labels that cannot be plotted without overlapping are hidden.

Let's label that previous plot.

```{.julia}
p = plot(mammals,
         {:x => "body", :y => "brain", :label => 1},
         Geom.label, Geom.point, Scale.x_log10, Scale.y_log10)
draw(SVG(6inch, 6inch), p)
```

Mapping `:label` to 1, gives the first column of the data frame, which is not
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
         {:x => "x"},
         Geom.bar)
draw(SVG(4inch, 3inch), p)
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
                   {:x => "x", :y => "y"},
                   Geom.rectbin)

draw(SVG(5inch, 4inch), p)
```


## Boxplots

The boxplot geometry shows the distribution of the y aesthetic, grouped by the x
aesthetic. Here is a (log) wage distribution categorized by years of education.

```{.julia}
wages = data("plm", "Wages")
p = plot(wages,
         {:x => "ed",
          :y => "lwage"},
         Geom.boxplot)
draw(SVG(4inch, 4inch), p)
```


## Plotting functions

Though Gadfly primarily plots data frames, there are convenience functions to do
simple function plotting.

```{.julia}
p = plot([sin, cos], 0, 25)
draw(SVG(6inch, 3inch), p)
```

This form of `plot` takes one or more functions, followed by a lower and upper
bounds over which the function will be plotted.


## Interactivity

Some basic interactivity is planned by embedding javascript in the SVG files
generated by Compose. As a proof of concept, names within color keys (e.g. in
the color categorized iris plot, or the sin/cos plot) can be used to toggle the
plotted data on or off.

Much more can and will be done in the future.

## Compose

Gadfly is based on a declarative vector graphics system called
[Compose](https://github.com/dcjones/Compose.jl). This let's one do interesting
things with plots, once they are defined.

```{.julia}
fig1a = plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width"}, Geom.point)
fig1b = plot(iris, {:x => "Sepal.Width"}, Geom.bar)
fig1 = hstack(fig1a, fig1b)

draw(SVG(6inch, 3inch), fig1)
```

Ultimately Compose will allow the creation of more complex plots, such as those
containing facets, or plots within plots.

