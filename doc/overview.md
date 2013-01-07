
# A Quick Overview of Gadfly

Gadfly is a system for plotting and visualization based largly on Hadley
Wickhams's `ggplot2` for R, and Leland Wilkinson's book "The Grammar of
Graphics".

This document will give a quick overview of the current state of Gadfly's
capabilities. The markdown version of this document is also executable, using
the Gadfly.weave function, generating a self-contained html file, and so it can
also be used to check that your installation of Gadfly works as advertised.

## Installation

Gadfly can be installed from the Julia repl quite easily.

```{.julia execute="false"}
require("Pkg")
import Pkg
Pkg.add("Gadfly")
```

## Simple plots

We'll need some data to plot. Plotting is primarily performed on DataFrame
objects. The RDatasets has a treasure trove of examples we can use.

```{.julia}
require("RDatasets")
using RDatasets
```

Fisher's measurements on irises is a good first data set.

```{.julia .img}
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
the graphic directly into the document. To generate these images individualle,
you should include a file name: `SVG("iris_plot.svg", 6inch, 4inch)`

## Aesthetics

Every geometry has some set of required and optional aesthetics. The point
geometry requires that `:x` and `:y` be mapped, and has the optional aesthetic
`:color` which will group points categorically indicated by color.

```{.julia .img}
p = plot(iris,
         {:x => "Sepal.Length", :y => "Sepal.Width", :color => "Species"},
         Geom.point)
draw(SVG(6inch, 4inch), p)
```

## Scale Transformations

Scale transforms also work as expected. Let's look at some data where this is
useful.

```{.julia .img}
mammals = data("MASS", "mammals")

p = plot(mammals,
         {:x => "body", :y => "brain"},
         Geom.point)
draw(SVG(5inch, 5inch), p)
```

This is no good, the elephants are ruining things for us. Putting both axis on a
log-scale clears things up.

```{.julia .img}
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

```{.julia .img}
p = plot(mammals,
         {:x => "body", :y => "brain", :label => 1},
         Geom.point, Geom.label, Scale.x_log10, Scale.y_log10)
draw(SVG(6inch, 6inch), p)
```

Mapping `:label` to 1, gives the first column of the data frame, which is not
named, but contains the species that each measurement was made on.


## Histograms

The bar geometry applies the `Stat.histogram` statistic by default, producing a
histogram.

```{.julia .img}
require("Distributions")
using Distributions

require("DataFrames")
using DataFrames

normmix = DataFrame({"x" => vcat(rand(Normal(-5), 500),
                                 rand(Normal(5), 500))})
p = plot(normmix,
         {:x => "x"},
         Geom.bar)
draw(SVG(4inch, 3inch), p)
```

No need to specify the number of bins, if not given a reasonable number is
chosen using a penalized maximum likelihood procedure.


## Boxplots

The boxplot geometry shows the distribution of the y aesthetic, grouped by the x
aesthetic. Here is the (log) wage distribution categorized by years of education.

```{.julia .img}
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

```{.julia .img}
p = plot([sin, cos], 1, 25)
draw(SVG(6inch, 3inch), p)
```

This form of `plot` takes one or more functions, followed by a lower and upper
bounds over which the function will be plotted.

