```@meta
Author = "Daniel C. Jones"
```

# Geom.line

## Aesthetics

  * `x`: X-axis position.
  * `y`: Y-axis position.
  * `group` (optional): Group categorically.
  * `color` (optional): Group categorically and indicate by color.

## Arguments

  * `preserve_order`: Default behavior for `Geom.line` is to draw lines between
    points in order along the x-axis. If this option is true, lines will be
    drawn between points in the order they appear in the data. `Geom.path()` is
    `Geom.line(preserve_order=true)`.


## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 8cm)
```

```@example 1
plot(dataset("lattice", "melanoma"), x="Year", y="Incidence", Geom.line)
```

```@example 1
plot(dataset("Zelig", "approval"), x="Month",  y="Approve", color="Year", Geom.line)
```
