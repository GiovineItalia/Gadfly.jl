---
title: xrug
author: Daniel C. Jones
part: Guide
order: 1018
...

Draw a rug plot along the x-axis of a plot.

# Aesthetics
  * `x`: X positions of notches.

# Examples

```{.julia hide="true" results="none"}
using Gadfly
using Compose

Gadfly.set_default_plot_size(14cm, 8cm)
```

```julia
plot(x=rand(20), y=rand(20), Guide.xrug)
```
