---
title: Themes
author: Daniel Jones
order: 2
...

Many parameters controlling the appearance of plots can be overridden by passing
a `Theme` object to the `plot` function.

The constructor for `Theme` takes zero or more named argument each of which
overrides the default theme's value.


# Parameters

  * `default_color`: When the color aesthetic is not bound, geometry uses this
    color for drawing. (Color)
  * `default_point_size`: Size of points in the point and boxplot geometry.
     (Measure)
  * `line_width`: Width of lines in the line geometry. (Measure)
  * `panel_fill`: Background color used in the main plot panel. (
    Color or Nothing)
  * `panel_opacity`: Opacity of the plot background panel. (Float in [0.0, 1.0])
  * `panel_stroke`: Border color of the main plot panel. (Color or
    Nothing)
  * `background_color`: Background color for the entire plot. If nothing, no
    background. (Color or Nothing)
  * `plot_padding`: How much padding should be put around the plot as a whole (Measure)
  * `grid_color`: Color of grid lines. (Color or Nothing)
  * `grid_color_focused`: In the D3 backend, mousing over the plot makes the
    grid lines emphasised by transitioning to this color. (Color or Nothing)
  * `grid_line_width`: Width of grid lines. (Measure)
  * `minor_label_font`: Font used for minor labels such as guide entries and
    labels. (String)
  * `minor_label_font_size`: Font size used for minor labels. (Measure)
  * `minor_label_color`: Color used for minor labels. (Color)
  * `major_label_font`: Font used for major labels such as guide titles and axis
    labels. (String)
  * `major_label_font_size`: Font size used for major labels. (Measure)
  * `major_label_color`: Color used for major labels. (Color)
  * `key_position`: Where key should be placed relative to the plot panel. One
    of `:left`, `:right`, `:top`, `:bottom`, or `:none`. Setting to `:none`
    disables the key. (Symbol)
  * `key_title_font`: Font used for titles of keys. (String)
  * `key_title_font_size`: Font size used for key titles. (Measure)
  * `key_title_color`: Color used for key titles. (Color)
  * `key_label_font`: Font used for key entry labels. (String)
  * `key_label_font_size`: Font size used for key entry labels. (Measure)
  * `key_label_color`: Color used for key entry labels. (Color)
  * `key_max_columns`: Maximum number of columns for key entry labels. (Int)
  * `bar_spacing`: Spacing between bars in `Geom.bar`. (Measure)
  * `boxplot_spacing`: Spacing between boxplots in `Geom.boxplot`. (Measure)
  * `errorbar_cap_length`: Length of caps on error bars. (Measure)
  * `highlight_width`: Width of lines drawn around plot geometry like points,
    and boxplot rectangles. (Measure)
  * `highlight_color`: Color used to outline plot geometry. This is a function
    that alters (e.g. darkens) the fill color of the geometry. (Function)
  * `lowlight_color`: Color used to draw background geometry, such as
    `Geom.ribbon`. This is a function tha altern the fill color of the geometry.
    (Function)
  * `lowlight_opacity`: Opacity of background geometry such as `Geom.ribbon`.
    (Float64)
  * `middle_color`: Color altering function used to draw the midline in
    boxplots. (Function)
  * `middle_width`: Width of the middle line in boxplots. (Measure)
  *  `guide_title_position`: One of `:left`, `:center`, `:right` indicating the
     placement of the title of color key guides. (Symbol)
  * `colorkey_swatch_shape`: The shape used in color swatches in the color key
    guide. Either `:circle` or `:square`  (Symbol)
  * `bar_highlight`: Color used to stroke bars in bar plots. If a function is
    given, it's used to transform the fill color of the bars to obtain a stroke
    color. (Function, Color, or Nothing)

# Examples

```{.julia hide="true" results="none"}
using RDatasets
using Gadfly

Gadfly.set_default_plot_size(12cm, 8cm)
srand(12345)
```

```julia
plot(x=rand(10), y=rand(10),
     Theme(panel_fill=colorant"black", default_color=colorant"orange"))
```
