```@meta
Author = "Mattriks"
```

# Geom.segment

Draw separate line segments/vectors/arrows.

!!! note

    If you want arrows, then you need to provide a `Scale` object for both axes. See example below.

## Aesthetics

  * `x`: Start of line segment.
  * `y`: Start of line segment.
  * `xend`: End of line segment.
  * `yend`: End of line segment.
  * `color` (optional): Color of line segments.

## Arguments

  * `arrow`: Default behavior for `Geom.segment` is to draw line segments without arrows. `Geom.vector` is `Geom.segment(arrow=true)`.


## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(14cm, 14cm)
```

```@example 1
seals = RDatasets.dataset("ggplot2","seals")
seals[:Latb] = seals[:Lat] + seals[:DeltaLat]
seals[:Longb] = seals[:Long] + seals[:DeltaLong]
seals[:Angle] = atan2(seals[:DeltaLat], seals[:DeltaLong])

coord = Coord.cartesian(xmin=-175.0, xmax=-119, ymin=29, ymax=50)
# Geom.vector also needs scales for both axes:
xsc  = Scale.x_continuous(minvalue=-175.0, maxvalue=-119)
ysc  = Scale.y_continuous(minvalue=29, maxvalue=50)
colsc = Scale.color_continuous(minvalue=-3, maxvalue=3)

layer1 = layer(seals, x=:Long, y=:Lat, xend=:Longb, yend=:Latb, Geom.vector, color=:Angle)

plot(layer1, xsc, ysc, colsc, coord)
```
