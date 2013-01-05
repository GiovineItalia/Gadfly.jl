# Gadfly

Gadfly is an implementation of a Wickham-Wilkinson style grammar of graphics in
Julia.

Parts of it are functional, but is very much incomplete and a work in progress.
Some basic plots can be drawn, but more importantly, it provides a basis for a
powerful, extensible, and efficient visualization system.

Stay tuned. More to come.

# Preview

Here's an example of what works so far:

![Histogram](http://dcjones.github.com/gadfly/iris3.svg)

```julia
# Plot some data with Gadfly!

# Grab some example datasets
load("RDatasets")
using RDatasets

load("Gadfly")
using Gadfly

# Load some arbitrary data.
iris = data("datasets", "iris")

# Construct a plot definition.
p = plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width", :color => "Species"},
         Geom.point)

# Draw the graphic as an SVG image.
draw(SVG("some_plot.svg", 6inch, 4inch), p)
```

Gadfly uses a declarative vector graphics system called
[Compose](https://github.com/dcjones/compose). This let's you manipulate plots
in interesting ways once you define them.

![Histogram](http://dcjones.github.com/gadfly/fig1.svg)

```julia
fig1a = render(plot(iris, {:x => "Sepal.Length", :y => "Sepal.Width"},
                    Geom.point))
fig1b = render(plot(iris, {:x => "Sepal.Width"}, Geom.bar))
fig1 = hstack(fig1a, fig1b)

img = SVG("fig1.svg", 9inch, 4inch)
draw(img, fig1)
```

