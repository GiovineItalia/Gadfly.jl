# Stat.y_jitter

Nudge values on the y-axis to avoid overplotting.

## Asethetics
  * `y`: Data to nudge.

## Arguments
  * `range`: Maximum jitter is this number times the resolution of the data,
    where the "resolution" is the smallest non-zero difference between two
    points.
  * `seed`: Seed for RNG used to randomly jitter values.

## Examples

```@example 1
using Distributions # hide
using Gadfly # hide
Gadfly.set_default_plot_size(12cm, 8cm) # hide
srand(1234) # hide
nothing # hide
```

```@example 1
plot(x=rand(500), y=rand(1:4, 500), Stat.y_jitter(range=0.5), Geom.point)
```
