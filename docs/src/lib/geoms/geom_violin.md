```@meta
Author = "Daniel C. Jones"
```

# Geom.violin

Draw violin plots.

## Aesthetics

Aesthetics used directly:

  * `x`: Group categorically on the X-axis
  * `y`: Y-axis position.
  * `width`: Density at a given `y` value.
  * `color` (optional): Violin color.  A suitable discrete variable is needed here. See example below.

With the default statistic [Stat.violin](@ref), only the following need be defined:

  * `x` (optional): Group categorically on the X-axis.
  * `y`: Sample from which to draw the density plot.


## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
Dsing = dataset("lattice","singer")
Dsing[:Voice] = [x[1:5] for x in Dsing[:VoicePart]]
plot(Dsing, x=:VoicePart, y=:Height, color=:Voice, Geom.violin)
```
