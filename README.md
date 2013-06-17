
!["Alice looked up at the Rocking-horse-fly with great interest, and made up her
mind that it must have been just repainted, it looked so bright and sticky."](http://dcjones.github.com/Gadfly.jl/rockinghorsefly.png)

**Gadfly** is a plotting and data visualization system written in
[Julia](http://julialang.org/).

It's influenced heavily by Leland Wilkinson's book
[The Grammar of Graphics](http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html)
and Hadley Wickham's refinment of that grammar in
[ggplot2](http://ggplot2.org/).

It renders publication quality graphics to PNG, Postscript, PDF, SVG, and
Javascript. The Javascript backend uses [d3](http://d3js.org/) to add
interactivity like panning, zooming, and toggling.

To see Gadfly in action, have gander at some [examples](http://dcjones.github.io/Gadfly.jl/doc/).

# Installing

## Optional: install cairo, pango, and fontconfig

Gadfly works best with the C libraries cairo, pango, and fontconfig installed.
The PNG, PS, and PDF backends require cairo, but without it the SVG and
Javascript/D3 backends are still available.

Complex layouts involving text are also somewhat more accurate when pango and
fontconfig are available.

## Install Gadfly and dependencies

From the Julia REPL a reasonably up to data version can be installed with

```julia
Pkg.add("Gadfly")
```

This will likely result in half a dozen or so other packages also being
installed.

# Using

The "grammar of graphics" idiom using in Gadfly may seem a a little strange at
first, but once basic ideas are grasped, figuring out how to combine the pieces
to make a new plot is quite easy.

Specifying plot in Gadfly consists of three parts:

  1. A DataFrame containing the data you wish to plot.
  2. Bindings of "aesthetics" to columns or expressions from your data frame.
  3. Plot elements, which are statistics, scales, or geometries used to
     construct the graphic.

Here's a quick example.

```julia
using Gadfly
using RDataSets

# grab some data to plot
mammals = data("MASS", "mammals")

p = plot(mammals,
         x="body", y="brain", label=1,
         Scale.x_log10, Scale.y_log10,
         Geom.label, Geom.point)

# render the plot on a backend
draw(SVG("mammals.svg", 6inch, 6inch), p)
```

![Mammals](http://dcjones.github.com/Gadfly.jl/mammals.svg)


The data we are plotting is contained in `mammals`.

We bind columns from `mammals` to aesthetics, which are used by the plot
geometries to draw the graphic. Here we bind `x` to the body column, `y` to the
brain column, and `label` to column 1, which is an unnamed column containing the
animal's name.

Finally we add plot elements. We override the default linear scale with a log10
scale for both the x and y axis, add the label and point geometries.

# Elements

Plot elements in Gadfly are statistics, scales, geometries, and guides. Each
operates on data bound to aesthetics, but in different ways.

### Statistics

Statistics are functions taking as input one or more aesthetics, operating on
those values, then outputing one or more aesthetic. For example, drawing of
boxplots typically uses the boxplot statistic (Stat.boxplot) that takes as input
the `x` and `y` aesthetic, and outputs the middle, and upper and lower hinge,
and upper and lower fence aesthetics.

### Scales

Scales, similarly to statistics apply a transformation to the original data,
typically mapping one aesthetic to the same aethetic, while retaining the
original value. The `Scale.x_log10` aesthetic maps the `x` aesthetic back the
`x` aesthetic after appling a log10 transformation, but keeps track of the
original value so that data points are properly identified.

### Geometries

Finally geometries are responsible for actually doing the drawing. A geometry
takes as input one or aesthetics, and used data bound to these aesthetics to
draw things. The `Geom.point` geometry draws points using the `x` and `y`
aesthetics, the `Geom.lines` geometry draws lines, and so on.

### Guides

Very similar to geometries are guides, which draw graphics supported the actual
visualization, such al axis ticks and labels and color keys. The major
distinction is that geometries always draw within the rectangular plot frame,
while guides have some special layout considerations.


# Using the d3 backend

The `D3` backend writes javascript. Making use of it's output is slightly more
involved than with the image backends.

Rendering to Javascript is easy enough:

```julia
draw(D3("mammals.js", 6inch, 6inch), p)
```

Before the output can be included, you must include the d3 and gadfly javascript
libraries. The necessary include for Gadfly is "gadfly.js" which lives in the
src directory (so, by default `~/.julia/Gadfly/src/gadfly.js`).

D3 can be downloaded from [here](http://d3js.org/d3.v3.zip).

Now the output can be included in an HTML like.

```html
<script src="d3.min.js"></script>
<script src="gadfly.js"></script>

<!-- Placed whereever you want the graphic to be rendered. -->
<script src="mammals.js"></script>
```

The d3 backend is very new, so these directions may change in the future. (I.e.
I might start embedding d3 and gadfly javascript by default.)

