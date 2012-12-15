# Gadfly

Gadfly is an implementation of a Wickham-Wilkinson style grammar of graphics in
Julia.

Parts of it are functional, but is very much incomplete and a work in progress.
Some basic plots can be drawn, but more importantly, it provides a basis for a
powerful, extensible, and efficient visualization system.

Stay tuned. More to come.

# Preview

Here's an example of what works so far:

![Histogram](http://dcjones.github.com/gadfly/some_plot.svg)

```julia
# Plot some data with Gadfly!

# Grab some example datasets
load("RDatasets.jl")
using RDatasets

load("Gadfly.jl")
using Gadfly

load("Compose.jl")
using Compose

# Load some arbitrary data.
iris = data("datasets", "iris")

# Construct a plot definition.
p = plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width"}, Geom.point)

# Render that plot, producing a declarative definition of the graphic.
g = render(p)

# Draw the graphic as an SVG image.
img = SVG("some_plot.svg", 7inch, 4inch)
draw(img, g)
finish(img)
```

Gadfly uses a declarative vector graphics system called
[Compose](https://github.com/dcjones/compose). This let's you manipulate plots
in interesting ways once you define them.

![Histogram](http://dcjones.github.com/gadfly/two_plots.svg)

```julia
# Render two plots
figa = render(plot(iris, {:x => "Sepal.Width"}, Geom.bar))
figb = render(plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width"}, Geom.point))

# Now let's stick them together
figab = hstack(figa, figb)

# Draw the graphic as an SVG image.
img = SVG("two_plots.svg", 7inch, 4inch)
draw(img, figab)
finish(img)
```



