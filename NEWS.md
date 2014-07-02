

# Version 0.3.1

  * Contour plots using [Contour.jl](https://github.com/tlycken/Contour.jl).
    Added a `plot` variant `plot(f, xmin, xmax, ymin, ymax)` for drawing contour
    plots directly from a function.

  * Add a `group` aesthetic to allow plotting lines of the same color without
    using multiple layers.

  * Better herustics for choosing histogram bin counts.

  * Add `Guide.manual_color_key` which lets one completely specify the colors
    and entries in a color key.

  * Boxplot improvements and fixes. Allow `upper_fence < lower_fence`, better
    support for `x` being numerical.

  * Performance improvements courtesy of @timholy.

# Version 0.3.0

  * Reimplement panning/zooming on top of [Snap.svg](https://github.com/adobe-webplatform/Snap.svg)
    with the Compose `SVGJS` backend.

  * An improved layout system: axis labels are flipped and categorical color
    keys are wrapped automatically.

  * Default Theme changes.


