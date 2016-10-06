```@meta
Author = "Daniel C. Jones, Shashi Gowda"
```

# Themes

Many parameters controlling the appearance of plots can be overridden by passing
a `Theme` object to the `plot` function. Or setting the `Theme` as the current theme using `push_theme` (see also `pop_theme` and `with_theme` below).

The constructor for `Theme` takes zero or more named arguments each of which overrides the *default* value of the field.

## The Theme stack

Gadfly maintains a stack of themes and applies theme values from the topmost theme in the stack. This can be useful when you want to set a theme for multiple plots and then switch back to a previous theme.

`push_theme(t::Theme)` and `pop_theme()` will push and pop from this stack respectively. You can use `with_theme(f, t::Theme)` to set a theme as the current theme and call `f()`.

## `style`

You can use `style` to override the fields on top of the *current* theme at the top of the stack. `style(...)` returns a `Theme`. So it can be used with `push_theme` and `with_theme`.


## Parameters

These parameters can either be used with `Theme` or `style`

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
  * `bar_spacing`: Spacing between bars in [Geom.bar](@ref). (Measure)
  * `boxplot_spacing`: Spacing between boxplots in [Geom.boxplot](@ref). (Measure)
  * `errorbar_cap_length`: Length of caps on error bars. (Measure)
  * `highlight_width`: Width of lines drawn around plot geometry like points,
    and boxplot rectangles. (Measure)
  * `discrete_highlight_color` and `continuous_highlight_color`: Color used
    to outline plot geometry. This is a function that alters (e.g. darkens) the
    fill color of the geometry. (Function)
  * `lowlight_color`: Color used to draw background geometry, such as
    `Geom.ribbon`. This is a function that alters the fill color of the geometry.
    (Function)
  * `lowlight_opacity`: Opacity of background geometry such as [Geom.ribbon](@ref).
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
  * `discrete_color_scheme`: A `DiscreteColorScale` see [Scale.color_discrete_hue](@ref)
  * `continuous_color_scheme`: A `ContinuousColorScale` see [Scale.color_continuous](@ref)

## Examples

```@setup 1
using RDatasets
using Gadfly
Gadfly.set_default_plot_size(12cm, 8cm)
srand(12345)
```

```@example 1

dark_panel = Theme(
    panel_fill=colorant"black",
    default_color=colorant"orange"
)

plot(x=rand(10), y=rand(10), dark_panel)

```

Setting the font to Computer Modern to create a LaTeX-like look, and choosing a font size:

```@example 1
Gadfly.push_theme(dark_panel)

p = plot(x=rand(10), y=rand(10),
     style(major_label_font="CMU Serif",minor_label_font="CMU Serif",
           major_label_font_size=16pt,minor_label_font_size=14pt))

# can plot more plots here...

Gadfly.pop_theme()

p # hide
```

Same effect can be had with `with_theme`

```@example 1
Gadfly.with_theme(dark_panel) do

  plot(x=rand(10), y=rand(10),
       style(major_label_font="CMU Serif",minor_label_font="CMU Serif",
             major_label_font_size=16pt,minor_label_font_size=14pt))
end
nothing # hide
```

or

```@example 1

Gadfly.push_theme(dark_panel)

Gadfly.with_theme(
       style(major_label_font="CMU Serif",minor_label_font="CMU Serif",
             major_label_font_size=16pt,minor_label_font_size=14pt)) do

  plot(x=rand(10), y=rand(10))

end

Gadfly.pop_theme()
nothing # hide
```

## Named themes

To register a theme by name, you can extend `Gadfly.get_theme(::Val{:theme_name})` to return a Theme object.

```@example 1
Gadfly.get_theme(::Val{:orange}) =
    Theme(default_color=colorant"orange")

Gadfly.with_theme(:orange) do
  plot(x=[1:10;], y=rand(10), Geom.bar)
end
```

Gadfly comes built in with 2 named themes: `:default` and `:dark`. You can also set a theme to use by default by setting the `GADFLY_THEME` environment variable *before* loading Gadfly.

## The Dark theme

This is one of the two themes the ship with Gadfly the other being `:default`. Here are a few plots that use the dark theme.

```@example 1
Gadfly.push_theme(:dark)
nothing # hide
```

```@example 1
plot(dataset("datasets", "iris"),
    x="SepalLength", y="SepalWidth", color="Species", Geom.point)
```

```@example 1
using RDatasets

gasoline = dataset("Ecdat", "Gasoline")

plot(gasoline, x=:Year, y=:LGasPCar, color=:Country,
         Geom.point, Geom.line)
```

```@example 1
using DataFrames

xs = 0:0.1:20

df_cos = DataFrame(
    x=xs,
    y=cos(xs),
    ymin=cos(xs) .- 0.5,
    ymax=cos(xs) .+ 0.5,
    f="cos"
)

df_sin = DataFrame(
    x=xs,
    y=sin(xs),
    ymin=sin(xs) .- 0.5,
    ymax=sin(xs) .+ 0.5,
    f="sin"
)

df = vcat(df_cos, df_sin)
p = plot(df, x=:x, y=:y, ymin=:ymin, ymax=:ymax, color=:f, Geom.line, Geom.ribbon)
```

```@example 1
using Distributions

X = rand(MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0]), 10000);
plot(x=X[1,:], y=X[2,:], Geom.hexbin(xbincount=100, ybincount=100))
```

```@example 1
Gadfly.pop_theme()
```
