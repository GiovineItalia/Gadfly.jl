
This is a log of major changes in Gadfly between releases. It is not exhaustive.
Each release typically has a number of minor bug fixes beyond what is listed here.

# Version 1.x
* Support DataFrames.jl 0.19 changes in indexing (#1318)



# Version 1.1.0
 * Add `alpha` aesthetic, `Scale.alpha_continuous` and `Scale.alpha_discrete` (#1252)
 * Add `limits=(min= , max= )` to `Stat.histogram` (#1249)
 * Add dodged boxplots (#1246)
 * Add `Stat.dodge` (#1240) 
 * `Stat.smooth(method=:lm)` confidence bands (#1231)
 * Support AbstractVectors everywhere (e.g. `Guide.xticks(ticks=1:10)`) (#1293)

# Version 0.9.0
 * conditionally depend on DataFrames (#1204)
 * `Geom.abline`: add support for nonlinear `Scale` transformations (#1201)
 * drop support for Julia 0.6 (#1189)

# Version 0.8.0
  * Add `linestyle` aesthetic (#1181)
  * Add `Guide.shapekey` (#1156)
  * `Geom.contour`: add support for `DataFrame` (#1150) 

# Version 0.7.0

  * Support DataFrames.jl v0.11+ (#1090, #1129, #1131)
  * Change `Theme(grid_strokedash=)` to `Theme(grid_line_style=)` and include in docs (#1106)
  * Add `Geom.ellipse` (#1103)  
  * Improved SVG interactivity (#1037)

# Version 0.6.5

  * ColorKeys inside plot panel (#1087)
  * Add `Geom.hair` (#1076)
  * Shape module (#1050)
  * Boxplot improvements

# Version 0.6.4

  * Regression testing tools (#1020)
  
# Version 0.6.3

  * Wide format data (#1013)

# Version 0.6.2

  * Add `Geom.rect` (#993)
  * Add `Geom.vectorfield` (#992)
  * Unified size, color, shape aesthetics for Geom.point (#991)
  * {h,v}line point shapes

# Version 0.6.1

  * Add `Stat.smooth` (#983)

# Version 0.6.0

  * Dramatically speed up precompilation by removing old, duplicate code (#958)
  * Add `Geom.abline` (#957)
  * Add `Geom.density2d` (#959)
  * Drop support for Julia 0.4 (#954)

# Version 0.5.3

  * Support for size aesthetic for `Geom.point` (#952, @tlnagy & @Mattriks)
  * Various doc improvements (#923, #933, #943)
  * Improved Juno support (#920, @MikeInnes)

# Version 0.4.1

  * Add transformed continuous color scales (`Scale.color_{log,log10,log2,asinh,sqrt}`).

# Version 0.3.16

  * Fix a precompilation error when Cairo is not installed.

# Version 0.3.14-0.3.15

  * Miscellaneous performance improvements and bug fixes.

  * Precompilation support on julia 0.4.

  * Switch from the Color package to the new Colors package.

  * Add `Geom.beeswarm`

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

  * Options to statically position `Geom.label` labels. (#542)

  * Layers within `Geom.subplot_grid` now work correctly. (#528)

  * Add a `background_color` option in `Theme` to change the plot's background
    color. (#534)

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


