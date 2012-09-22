# Gadfly

Gadfly is an implementation of a Wickham-Wilkinson style grammar of graphics in
Julia.

Parts of it are functional, but is very much incomplete and a work in progress.
Some basic plots can be drawn, but more importantly, it provides a basis for a
powerful, extensible, and efficient visualization system.

Stay tuned. More to come.

# Preview

Here's an example of what works so far:

![Histogram](http://dcjones.github.com/gadfly/histogram_example.svg)

```julia
# Draw a simple histogram with Gadfly.

require("gadfly.jl")
require("distributions.jl")

import Distributions.*

n = 100000
x = rand(Normal(), n)

p = Plot()
p.data.x = x

# Scales
push(p.scales, scale_x_continuous)
push(p.scales, scale_y_continuous)

# Transforms
push(p.transforms, transform_x_identity)
push(p.transforms, transform_y_identity)

# Statistics
push(p.statistics, stat_x_ticks)
push(p.statistics, stat_y_ticks)

# Coordinates
p.coord = coord_cartesian

# Guides
push(p.guides, guide_background)
push(p.guides, guide_x_ticks)
push(p.guides, guide_y_ticks)

# Layers
layer = Layer()
layer.statistic = stat_histogram
layer.geom = geom_bar
push(p.layers, layer)

@upon SVG("try.svg", 7inch, 4inch) begin
    draw(pad!(render(p), 2mm))
end

```


It's now terse, or pretty (that's still to come), but it works.


