
This is a log of major changes in Gadfly between releases. It is not exhaustive.
Each release typically has a number of minor bug fixes beyond what is listed here.


# Version 0.3.13

  * Add a `push!` function allowing plots to be built incrementally.

  * Add `Stat.x_jitter` and `Stat.y_jitter`

  * Fix a missing key with `colorkey_swatch_shape=:circle`.

  * Fix grid lines breaking on repeated mouseovers.

  * Fix some histogram binning issues.

# Version 0.3.12

  * Add `Geom.polygon`

  * Add `Geom.violin`.

  * Add support for opacity (AlphaColorValue) in various places.

  * Fix infinite loop when the span of data is very small.

# Version 0.3.11

  * Options to statically position `Geom.label` labels. (Issue #542)

  * Layers within `Geom.subplot_grid` now work correctly. (Issue #528)

  * Add a `background_color` option in `Theme` to change the plot's background
    color. (Issue #534)

  * Rename color scales for increased consistency: `Scale.continuous_color` →
    `Scale.color_continuous` and `Scale.discrete_color` → `Scale.color_discrete`.

  * Add `Scale.color_none` to suppress default color scales.

  * Add an `order` named argument to `layer` to control the order in which
    layers are drawn.

  * Improve handling of Date and DateTime types.

  * Add `Guide.annotation` which allows arbitrary drawing on plots.

# Version 0.3.10

  * Support for [Patchwork.jl](https://github.com/shashi/Patchwork.jl)

  * Several fixes for plotting dates.

# Version 0.3.9

  * Transition from DateTime.jl to Dates.jl (or Base.Dates in Julia 0.4)

  * Several fixes for `Stat.contour`

  * Split the interface for pretty printing scales into a separate package:
    [Showoff.jl](https://github.com/dcjones/Showoff.jl)

# Version 0.3.8

  * Improvements to how scales work with subplots.

  * Support engineering notation for numbers.

  * Improved binning algorithm for histograms with discrete data.

# Version 0.3.7

  * Fix layer support in `Geom.subplot_grid`.

  * Support rastered geometry embedded in SVG plots.

  * Performance improvements.

  * Allow multiple geometries in the same layer.

# Version 0.3.6

  * Fixes for bar plots: non-number and categorical types, strange behavior when
    x and y are of unequal length.

  * Fix error in `Geom.subplot_grid` when both axis are set to "free".

# Version 0.3.5

  * Add `Stat.qq` to draw qq plots with data or distributions.

  * Fix incorrect ordering in discrete color scales.

  * Documentation.

  * Layout improvements.

# Version 0.3.4

  * Fixes for multiple layers in `Geom.subplot_grid`

  * Support contour plots using a matrix.

  * Add `Coord.subplot_grid` for more consistent subplot behavior.

  * Drop Julia 0.2 compatibility.

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


