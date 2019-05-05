```@meta
Author = "Tamas Nagy, Daniel C. Jones, Simon Leblanc, Mattriks"
```

# Tutorial

Gadfly is an implementation of a "grammar of graphics" style statistical
graphics system for Julia. This tutorial will outline general usage
patterns and will give you a feel for the overall system.

To begin, we need some data. Gadfly can work with data supplied
as either a [DataFrame](https://juliadata.github.io/DataFrames.jl/stable/) or
as plain AbstractArrays. In
this tutorial, we'll pick and choose some examples from the
[RDatasets](https://github.com/johnmyleswhite/RDatasets.jl) package.

Let us use Fisher's iris dataset as a starting point.

```@example 1
using Gadfly, RDatasets
iris = dataset("datasets", "iris")
set_default_plot_size(14cm, 8cm) # hide
nothing # hide
```

| Row | SepalLength | SepalWidth | PetalLength | PetalWidth | Species   |
|-----|-------------|------------|-------------|------------|-----------|
| 1   | 5.1         | 3.5        | 1.4         | 0.2        | setosa    |
| 2   | 4.9         | 3.0        | 1.4         | 0.2        | setosa    |
| 3   | 4.7         | 3.2        | 1.3         | 0.2        | setosa    |
| 4   | 4.6         | 3.1        | 1.5         | 0.2        | setosa    |
| 5   | 5.0         | 3.6        | 1.4         | 0.2        | setosa    |
| 6   | 5.4         | 3.9        | 1.7         | 0.4        | setosa    |
| ... | ...         | ...        | ...         | ...        | ...       |


## DataFrames

When used with a DataFrame, the `plot` function in Gadfly is of the form:

```julia
plot(data::AbstractDataFrame, elements::Element...; mapping...)
```

The first argument is the data to be plotted and the keyword arguments at the
end map "aesthetics" to columns in the data frame.  All input arguments between
`data` and `mapping` are some number of "elements", which are the nouns and
verbs, so to speak, that form the grammar.

Let's get to it.

```@example 1
p = plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point);
nothing # hide
```

First note that we've taken advantage of the flexibility of Julia's
handling of function signatures and put the keyword arguments in the midst of
the positional arguments.  This is purely for ease of reading.

The example above produces a `Plot` object. It can be saved to a file by
drawing to one or more backends using `draw`.

```@example 1
img = SVG("iris_plot.svg", 14cm, 8cm)
draw(img, p)
nothing # hide
```

Now we have the following charming little SVG image.

```@example 1
p # hide
```

If you are working at the REPL, a quicker way to see the image is to omit
the semi-colon trailing `plot`.  This automatically renders the image to
your default multimedia display, typically an internet browser.  No need
to capture the output argument in this case.

```julia
plot(iris, x=:SepalLength, y=:SepalWidth)
```

Note that `Geom.point` will be automatically supplied if no other geometries
are given.

Alternatively one can manually call `display` on a `Plot` object.  This
workflow is necessary when `display` would not otherwise be called
automatically.

```julia
function get_to_it(d)
  ppoint = plot(d, x=:SepalLength, y=:SepalWidth, Geom.point)
  pline = plot(d, x=:SepalLength, y=:SepalWidth, Geom.line)
  ppoint, pline
end
ps = get_to_it(iris)
map(display, ps)
```

For the rest of the demonstrations, we'll simply omit the trailing semi-colon
for brevity.

In this plot we've mapped the x aesthetic to the `SepalLength` column and the y
aesthetic to the `SepalWidth`. The last argument, [`Geom.point`](@ref
Gadfly.Geom.point), is a geometry element which takes bound aesthetics and
renders delightful figures. Adding other geometries produces layers, which may
or may not result in a coherent plot.

```@example 1
plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point, Geom.line)
```

This is the grammar of graphics equivalent of "colorless green ideas sleep
furiously". It is valid grammar, but not particularly meaningful.


## Arrays

If by chance your data are stored in Arrays instead of a DataFrame, fear not,
identical plots can be created using an alternate `plot` signature:

```julia
plot(elements::Element...; aesthetics...)
```

Here, the keyword arguments directly supply the data to be plotted,
instead of using them to indicate which columns of a DataFrame to use.

```@example 1
SepalLength = iris[:SepalLength]
SepalWidth = iris[:SepalWidth]
plot(x=SepalLength, y=SepalWidth, Geom.point,
     Guide.xlabel("SepalLength"), Guide.ylabel("SepalWidth"))
nothing # hide
```

Note that with the Array interface, extra elements must be included to specify the
axis labels, whereas with a DataFrame they default to the column names.

## Color

Let's do add something meaningful by mapping the color aesthetic.

```@example 1
plot(iris, x=:SepalLength, y=:SepalWidth, color=:Species, Geom.point);

# or equivalently for Arrays:
SepalLength = iris[:SepalLength] # hide
SepalWidth = iris[:SepalWidth] # hide
Color = iris[:Species]
plot(x=SepalLength, y=SepalWidth, color=Color, Geom.point,
     Guide.xlabel("SepalLength"), Guide.ylabel("SepalWidth"),
     Guide.colorkey(title="Species"))
```

Ah, a scientific discovery: Setosa has short but wide sepals!

Color scales in Gadfly by default are produced from perceptually uniform
colorspaces (LUV/LCHuv or LAB/LCHab), though it supports RGB, HSV, HLS, XYZ, and
converts arbitrarily between these. Of course, CSS/X11 named colors work too:
"old lace", anyone?

All aesthetics (e.g. `x`, `y`, `color`) have a Scale e.g. `Scale.x_continuous()` and some have a Guide e.g. `Guide.xticks()`.  [Scales](@ref) can be continuous or discrete.

## Continuous Scales

| Aesthetic | Scale. | Guide. |
|-----------|------------------|-------|
| `x` | `x_continuous` | `xticks` |
| `y` | `y_continuous` | `yticks` |
| `color` | `color_continuous` | `colorkey` |
| `size`  | `size_continuous`  | sizekey (tbd)  |
| `alpha` | `alpha_continuous` | alphakey (tbd) |

e.g. `Scale.x_continuous(format= , minvalue= , maxvalue= )`\
`format` can be: `:plain`, `:scientific`, `:engineering`, or `:auto`.

Continuous scales can be transformed. In the next plot, the large animals are ruining things for us. Putting both axes on a log-scale clears things up.

```@example 1
set_default_plot_size(21cm ,8cm)
mammals = dataset("MASS", "mammals")
p1 = plot(mammals, x=:Body, y=:Brain, label=:Mammal, Geom.point, Geom.label)
p2 = plot(mammals, x=:Body, y=:Brain, label=:Mammal, Geom.point, Geom.label,
     Scale.x_log10, Scale.y_log10)
hstack(p1, p2)
```

Scale transformations include: `_sqrt`, `_log`, `_log2`, `_log10`, `_asinh`.  
 
```@example 1
using Printf
Diamonds = dataset("ggplot2","diamonds")
p3= plot(Diamonds, x=:Price, y=:Carat, Geom.histogram2d(xbincount=25, ybincount=25),
    Scale.x_continuous(format=:engineering) )
p4= plot(Diamonds, x=:Price, y=:Carat, Geom.histogram2d(xbincount=25, ybincount=25),
    Scale.x_continuous(format=:plain), 
    Scale.y_sqrt(labels=y->@sprintf("%i", y^2)),
    Scale.color_log10(minvalue=1.0, maxvalue=10^4),
    Guide.yticks(ticks=sqrt.([0:5;])) )
hstack(p3, p4)
```


## Discrete Scales

| Aesthetic | Scale. | Guide. |
|-----------|------------------|-------|
| `x` | `x_discrete` | `xticks` |
| `y` | `y_discrete` | `yticks` |
| `color` | `color_discrete` | `colorkey` |
| `shape` | `shape_discrete` | `shapekey` |
| `size` | `size_discrete` | sizekey (tbd) |
| `linestyle` | `linestyle_discrete` | linekey (tbd) |
| `alpha`  | `alpha_discrete` | alphakey (tbd) |
| `group`  | `group_discrete` |  |
| `xgroup` | `xgroup` |  |
| `ygroup` | `ygroup` |  |

e.g. `Scale.shape_discrete(labels= , levels= , order= )`

```@example 1
mtcars = dataset("datasets","mtcars")
 labeldict = Dict(4=>"four", 6=>"six", 8=>"eight")
p5 = plot(mtcars, x=:Cyl, color=:Cyl, Geom.histogram,
    Scale.x_discrete(levels=[4,6,8]), Scale.color_discrete(levels=[4,6,8]) )
p6 = plot(mtcars, x=:Cyl, color=:Cyl, Geom.histogram,
    Scale.x_discrete(labels=i->labeldict[i], levels=[8,6,4]), 
    Scale.color_discrete(levels=[8,6,4]) )
hstack(p5, p6)
```


## Gadfly defaults

If you don't supply Scales or Guides, Gadfly will make an educated guess.

```@example 1
set_default_plot_size(14cm, 8cm) # hide
gasoline = dataset("Ecdat", "Gasoline")
plot(gasoline, x=:Year, y=:LGasPCar, color=:Country, Geom.point, Geom.line)
```

We could have added [`Scale.x_discrete`](@ref Gadfly.Scale.x_discrete)
explicitly, but this is detected and the right default is chosen. This is the
case with most of the elements in the grammar. When we've omitted
[`Scale.x_continuous`](@ref Gadfly.Scale.x_continuous) and
[`Scale.y_continuous`](@ref Gadfly.Scale.y_continuous) in the plots above,
as well as [`Coord.cartesian`](@ref), and guide elements such as
[`Guide.xticks`](@ref Gadfly.Guide.xticks), [`Guide.xlabel`](@ref
Gadfly.Guide.xlabel) and so on, Gadfly tries to fill
in the gaps with reasonable defaults.

## Rendering

Gadfly uses a custom graphics library called
[Compose](https://github.com/GiovineItalia/Compose.jl), which is an attempt at
a more elegant, purely functional take on the R
[grid](https://www.rdocumentation.org/packages/grid) package. It allows mixing
of absolute and relative units and complex coordinate transforms.  The primary
backend is a native [SVG](https://www.w3.org/Graphics/SVG/) generator (almost
native: it uses [pango](https://www.pango.org/) to precompute text extents),
though there is also a [Cairo](https://cairographics.org/) backend for PDF and
PNG.  See [Backends](@ref) for more details.

Building graphics declaratively let's you do some fun things. Like stick two
plots together:

```@example 1
set_default_plot_size(21cm, 8cm) # hide
fig1a = plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point)
fig1b = plot(iris, x=:SepalWidth, Geom.bar)
fig1 = hstack(fig1a, fig1b)
```

Ultimately this will make more complex visualizations easier to build. For
example, facets, plots within plots, and so on. See [Compositing](@ref) for
more details.

## Interactivity

One advantage of generating our own SVG is that we can annotate our SVG output
and embed Javascript code to provide some level of dynamism.  Though not a
replacement for full-fledged custom interactive visualizations of the sort
produced by [D3](https://d3js.org/), this sort of mild interactivity can
improve a lot of standard plots.

The fuel efficiency plot is made more clear by toggling off some of the
countries, for example.  To do so, first render the plot using the SVGJS
backend, which was *not* used to generate this webpage but is the default at
the REPL, then simply click or shift-click in the colored squares in the table
of keys to the right.

One can also zoom in and out by pressing the shift key while either scrolling
the mouse wheel or clicking and dragging a box.  Should your mouse not work,
try the plus, minus, I, and O, keys.  Panning is similarly easy: click and drag
without depressing the shift key, or use the arrow keys.  For Vim enthusiasts,
the H, J, K, and L keys pan as expected.  To reset the plot to it's initial
state, double click it or hit R.  Lastly, press C to toggle on and off a
numerical display of the cursor coordinates.
