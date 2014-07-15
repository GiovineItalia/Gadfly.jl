
# Version 0.3.3

  * Add `fixed` and `aspect_ratio` arguments to `Coord.cartesian` to control a
    plot's aspect ratio.

  * A PGF backend, allowing plots to be rendered as TeX documents.

  * Reimplement toggleable color keys in the SVGJS backend.

# Version 0.3.2

  * Bug fix release.

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


