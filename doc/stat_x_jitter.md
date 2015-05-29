---
title: x_jitter
author: Daniel C. Jones
part: Statistic
order: 1003
...

Nudge values on the x-axis to avoid overplotting.

# Asethetics
  * `x`: Data to nudge.

# Arguments
  * `range`: Maximum jitter is this number times the resolution of the data,
    where the "resolution" is the smallest non-zero difference between two
    points.
  * `seed`: Seed for RNG used to randomly jitter values.

# Examples

```{.julia hide="true" results="none"}
using Gadfly, Distributions

Gadfly.set_default_plot_size(14cm, 8cm)
srand(1234)
```

```julia
plot(x=rand(1:4, 500), y=rand(500), Stat.x_jitter(range=0.5), Geom.point)
```

