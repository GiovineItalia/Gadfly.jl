# Parameters controlling how a plot appears

const title_font_desc = "'PT Sans','Helvetica Neue','Helvetica',sans-serif"
const label_font_desc = "'PT Sans Caption','Helvetica Neue','Helvetica',sans-serif"

# Choose highlight color by darkening the fill color
default_discrete_highlight_color(fill_color::Color) = RGB(1, 1, 1)

default_discrete_highlight_color(fill_color::TransparentColor) = RGBA{Float32}(
        default_discrete_highlight_color(color(fill_color)), fill_color.alpha)

function default_continuous_highlight_color(fill_color::Color)
    c = convert(LCHab, fill_color)
    return LCHab(max(0, c.l - 40), c.c, c.h)
end

default_continuous_highlight_color(fill_color::TransparentColor) = RGBA{Float32}(
        default_continuous_highlight_color(color(fill_color)), fill_color.alpha)

function default_stroke_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    c = LCHab(fill_color.l, fill_color.c, fill_color.h)
    LCHab(c.l - 15, c.c, c.h)
end

default_stroke_color(fill_color::TransparentColor) = RGBA{Float32}(
        default_stroke_color(color(fill_color)), fill_color.alpha)

function default_lowlight_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    c = LCHab(fill_color.l, fill_color.c, fill_color.h)
    LCHab(90, 20, c.h)
end

function default_lowlight_color(fill_color::TransparentColor)
    @warn "For opacity, use `Theme(alphas=[a])` and/or `Scale.alpha_discrete()`, or use `Scale.alpha_continuous()`"   
   RGBA{Float32}(Gadfly.default_lowlight_color(color(fill_color)), fill_color.alpha)
end

# Choose a middle color by darkening the fill color
function default_middle_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    LCHab(fill_color.l + 40, fill_color.c, fill_color.h)
end

default_middle_color(fill_color::TransparentColor) = RGBA{Float32}(
        default_middle_color(color(fill_color)), fill_color.alpha)
 
get_stroke_vector(::Nothing) = []
get_stroke_vector(vec::AbstractVector) = vec
function get_stroke_vector(linestyle::Symbol)
    ldash = 6 * Compose.mm
    dash = 4 * Compose.mm
    dot = 2 * Compose.mm
    gap = 1 * Compose.mm
    linestyle == :solid && return []
    linestyle == :dash && return [dash, gap]
    linestyle == :dot && return [dot, gap]
    linestyle == :dashdot && return [dash, gap, dot, gap]
    linestyle == :dashdotdot && return [dash, gap, dot, gap, dot, gap]
    linestyle == :ldash && return [ldash, gap]
    linestyle == :ldashdash && return [ldash, gap, dash, gap]
    linestyle == :ldashdot && return [ldash, gap, dot, gap]
    linestyle == :ldashdashdot && return [ldash, gap, dash, gap, dot, gap]
    error("unsupported linestyle: ", linestyle)
end

using DocStringExtensions

"""
$(FIELDS)
"""
@varset Theme begin
    "If the color aesthetic is not mapped to anything, this is the color that is used.  (Color)",
    default_color,         ColorOrNothing,  LCHab(70, 60, 240)

    "Size of points in the point, boxplot, and beeswarm geometries.  (Measure)",
    point_size,            Measure,         0.9mm
    "Minimum size of points in the point geometry.  (Measure)",
    point_size_min,        Measure,         0.45mm
    "Maximum size of points in the point geometry.  (Measure)",
    point_size_max,        Measure,         1.8mm

    "Shapes of points in the point geometry.  (Function in circle, square, diamond, cross, xcross, utriangle, dtriangle, star1, star2, hexagon, octagon, hline, vline)",
    point_shapes,          Vector{Function},  [Shape.circle, Shape.square, Shape.diamond, Shape.cross, Shape.xcross,
                                               Shape.utriangle, Shape.dtriangle, Shape.star1, Shape.star2,
                                               Shape.hexagon, Shape.octagon, Shape.hline, Shape.vline]

    "Width of lines in the line geometry. (Measure)",
    line_width,            Measure,         0.3mm

    "Style of lines in the line geometry. The default palette is `[:solid, :dash, :dot, :dashdot, :dashdotdot, :ldash, :ldashdash, :ldashdot, :ldashdashdot]` which is a Vector{Symbol}, or customize using Vector{Vector{<:Measure}}",
    line_style,            (Vector{<:Union{Symbol, Vector{<:Measure}}}),   [:solid, :dash, :dot, :dashdot, :dashdotdot, :ldash, :ldashdash, :ldashdot, :ldashdashdot]

    "Alpha palette. The default palette is [1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0]. Customize using a Vector of length one or greater, with 0.0≤values≤1.0",
    alphas,         Vector{Float64}, [1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0]

    "Background color used in the main plot panel. (Color or Nothing)",
    panel_fill,            ColorOrNothing,  nothing

    "Border color of the main plot panel. (Color or Nothing)",
    panel_stroke,          ColorOrNothing,  nothing

    "Opacity of the plot background panel. (Float in [0.0, 1.0])",
    panel_opacity,         Float64,         0.0,
    "The keyword argument `panel_opacity` has been deprecated. Instead, provide a e.g. RGBA() color to panel_fill."

    "Background color for the entire plot. If nothing, no background. (Color or Nothing)",
    background_color,      ColorOrNothing,  nothing

    "Padding around the plot. The order of padding is: `plot_padding=[left, right, top, bottom]`. If a vector of length one is provided e.g.  `[5mm]` then that value is applied to all sides. Absolute or relative units can be used. (Vector{<:Measure})",
    plot_padding,          (Vector{<:Measure}),         [5mm]

    "Color of grid lines. (Color or Nothing)",
    grid_color,            ColorOrNothing,  colorant"#D0D0E0"
    "Style of grid lines. (Symbol in :solid, :dash, :dot, :dashdot, :dashdotdot, or Vector of Measures)",
    grid_line_style,       Union{Symbol,Vector},   [0.5mm, 0.5mm]

    "In the D3 backend, mousing over the plot makes the grid lines emphasised by transitioning to this color. (Color or Nothing)",
    grid_color_focused,    ColorOrNothing,  colorant"#A0A0A0"

    "Width of grid lines. (Measure)",
    grid_line_width,       Measure,         0.2mm

    "Font used for minor labels such as tick labels and entries in keys. (String)",
    minor_label_font,      AbstractString,          label_font_desc
    "Font size used for minor labels. (Measure)",
    minor_label_font_size, Measure,         8pt
    "Color used for minor labels. (Color)",
    minor_label_color,     ColorOrNothing,  colorant"#6c606b"

    "Font used for major labels such as guide titles and axis labels. (String)",
    major_label_font,      AbstractString,          title_font_desc
    "Font size used for major labels. (Measure)",
    major_label_font_size, Measure,         11pt
    "Color used for major labels. (Color)",
    major_label_color,     ColorOrNothing,  colorant"#564a55"

    "Font used for labels in Geom.label. (String)",
    point_label_font,      AbstractString,          label_font_desc
    "Font size used for labels. (Measure)",
    point_label_font_size, Measure,         8pt
    "Color used for labels. (Color)",
    point_label_color,     ColorOrNothing,  colorant"#4c404b"

    "Font used for titles of keys. (String)",
    key_title_font,      AbstractString,          title_font_desc
    "Font size used for key titles. (Measure)",
    key_title_font_size, Measure,         11pt
    "Color used for key titles. (Color)",
    key_title_color,     ColorOrNothing,  colorant"#362a35"

    "Font used for key entry labels. (String)",
    key_label_font,      AbstractString,          title_font_desc
    "Font size used for key entry labels. (Measure)",
    key_label_font_size, Measure,         8pt
    "Color used for key entry labels. (Color)",
    key_label_color,     ColorOrNothing,  colorant"#4c404b"

    "How many gradations to show in a continuous color key. (Int)",
    key_color_gradations, Int,            40

    "Spacing between bars in [`Geom.bar`](@ref). (Measure)",
    bar_spacing,           Measure,         -0.05mm

    "Spacing between boxplots in [`Geom.boxplot`](@ref). (Measure)",
    boxplot_spacing,       Measure,         1mm

    "Length of caps on error bars. (Measure)",
    errorbar_cap_length,   Measure,         3mm

    # SEEMS TO BE ONLY USED BY GEOM.ERRORBAR ???
    # Lines are drawn in a slightly different color than fills, e.g. to
    # differentiate histogram bars from error bars.
    stroke_color,          Function,       default_stroke_color

    "Width of lines drawn around plot geometry like points, and boxplot rectangles. (Measure)",
    highlight_width,       Measure,         0.3mm

    "Color used to outline plot geometry. This is a function that alters (e.g. darkens) the fill color of the geometry. (Function)",
    discrete_highlight_color,       Function,        default_discrete_highlight_color
    "Color used to outline plot geometry. This is a function that alters (e.g. darkens) the fill color of the geometry. (Function)",
    continuous_highlight_color,     Function,        default_continuous_highlight_color

    "Color used to draw background geometry, such as `Geom.ribbon` and `Geom.polygon`. This is a function that alters the fill color of the geometry.  (Function)",
    lowlight_color,        Function,        default_lowlight_color

    "Opacity of background geometry such as [`Geom.ribbon`](@ref).  (Float64)",
    lowlight_opacity,      Float64,         0.6,
    "The keyword argument `lowlight_opacity` has been deprecated, and never worked anyway!"

    "Color altering function used to draw the midline in boxplots. (Function)",
    middle_color,          Function,        default_middle_color

    "Width of the middle line in boxplots. (Measure)",
    middle_width,          Measure,         0.6mm

    "One of `:left`, `:center`, `:right` indicating the placement of the title of color key guides. (Symbol)",
    guide_title_position,  Symbol,          :left

    "The shape used in color swatches in the color key guide. Either `:circle` or `:square`  (Symbol)",
    colorkey_swatch_shape, Symbol,          :square

    # will eventually replace `colorkey_swatch_shape` 
    "Shape used in keys for swatches (Function as in `point_shapes`)",
    key_swatch_shape,       Function,        Shape.square

    "Default color used in keys for swatches.  Currently works for `Guide.shapekey` (Color)",
    key_swatch_color,       ColorOrNothing,        nothing

    "Where key should be placed relative to the plot panel. One of `:left`, `:right`, `:top`, `:bottom`, `:inside` or `:none`. Setting to `:none` disables the key. Setting to `:inside` places the key in the lower right quadrant of the plot. (Symbol)",
    key_position,          Symbol,          :right

    "Color used to stroke bars in bar plots. If a function is given, it's used to transform the fill color of the bars to obtain a stroke color. (Function, Color, or Nothing)",
    bar_highlight,         Union{Nothing, Function, Color},   nothing

    rug_size,             Measure,          2.0mm

    "Number of annealing iterations.  Used by `Geom.label(position=:dynamic)`",
    label_placement_iterations,  Int,       1000

    "Penalty for a label not being contained within the plot frame.  Used by `Geom.label(position=:dynamic)`",
    label_out_of_bounds_penalty, Float64,   10.0

    "Penalty for making a label hidden to avoid overlaps.  Used by `Geom.label(position=:dynamic)`",
    label_hidden_penalty,        Float64,   0.5

    "Probability of proposing a visibility flip during label layout.  Used by `Geom.label(position=:dynamic)`",
    label_visibility_flip_pr,    Float64,   0.2

    "Padding between marker and label.  Used by `Geom.label(position=:dynamic)`",
    label_padding,    Measure,   1mm

    "Maximum number of columns for key entry labels. (Int)",
    key_max_columns,             Int,       4

    "A `DiscreteColorScale` see [`Scale.color_discrete_hue`](@ref)",
    discrete_color_scale,        Scale.DiscreteColorScale, Scale.color_discrete()

    "A `ContinuousColorScale` see [`Scale.color_continuous`](@ref)",
    continuous_color_scale,      Scale.ContinuousColorScale, Scale.color_continuous()
end


### should we export {current,with,pop,push)_theme?
const theme_stack = Theme[Theme()]

"""
    current_theme()

Get the `Theme` on top of the theme stack.
"""
current_theme() = theme_stack[end]

"""
    style(; kwargs...) -> Theme

Return a new `Theme` that is a copy of the current theme as modifed by the
attributes in `kwargs`.  See [Themes](@ref) for available fields.

# Examples

```
style(background_color="gray")
```
"""
style(; kwargs...) = Theme(current_theme(); kwargs...)

"""
    push_theme(t::Theme)

Set the current theme by placing `t` onto the top of the theme stack.
See also [`pop_theme`](@ref) and [`with_theme`](@ref).
"""
function push_theme(t::Theme)
    push!(theme_stack, t)
    nothing
end

"""
    pop_theme() -> Theme

Return to using the previous theme by removing the top item on the theme stack.
See also [`pop_theme`](@ref) and [`with_theme`](@ref).
"""
function pop_theme()
    length(theme_stack) == 1 && error("There default theme cannot be removed")
    pop!(theme_stack)
end

"""
    push_theme(t::Symbol)
  
Push a `Theme` by its name.  Available options are `:default` and `:dark`.
See also [`get_theme`](@ref).
"""
push_theme(t::Symbol) = push_theme(get_theme(Val{t}()))

"""
    get_theme()

Register a theme by name by adding methods to `get_theme`.

# Examples

```
get_theme(::Val{:mytheme}) = Theme(...)
push_theme(:mytheme)
```
"""
get_theme(::Val{name}) where {name} = error("No theme $name found")

"""
    with_theme(f, theme)

Call function `f` with `theme` as the current `Theme`.
`theme` can be a `Theme` object or a symbol.

# Examples

```
with_theme(style(background_color=colorant"#888888"))) do
    plot(x=rand(10), y=rand(10))
end
```
"""
function with_theme(f, theme)
    push_theme(theme)
    p = f()
    pop_theme()
    p
end

"""
    get_theme(::Val{:default})

A dark foreground on a light background.
"""
get_theme(::Val{:default}) = Theme()


### Dark theme

const dark_theme = let label_color=colorant"#a1a1a1",
    bgcolor=colorant"#222831",
    grid_color=colorant"#575757",
    fgcol1=colorant"#FE4365",
    fgcol2=colorant"#eca25c",
    fgcol3=colorant"#3f9778",
    fgcol4=colorant"#005D7F"

    function border_color(fill_color)
        fill_color = convert(LCHab, fill_color)
        c = LCHab(fill_color.l, fill_color.c, fill_color.h)
        LCHab(60, 20, c.h)
    end


    function gen_dark_colors(n)
      cs = distinguishable_colors(n, [fgcol1, fgcol2,fgcol3],
          lchoices=Float64[58, 45, 72.5, 90],
          transform=c -> deuteranopic(c, 0.1),
          cchoices=Float64[20,40],
          hchoices=[75,51,35,120,180,210,270,310]
      )

      convert(Vector{Color}, cs)
    end

    function lowlight_color(fill_color)
        fill_color = convert(LCHab, fill_color)
        c = LCHab(fill_color.l, fill_color.c, fill_color.h)
        c2 = convert(RGBA, LCHab(c.l, 50, c.h))
        RGBA(c2.r, c2.g, c2.b, .53)
    end

    function dark_theme_discrete_colors(;
        levels=nothing,
        order=nothing,
        preserve_order=true)

        Gadfly.Scale.DiscreteColorScale(
            gen_dark_colors,
            levels=levels,
            order=order,
            preserve_order=preserve_order
        )
    end

    function dark_theme_continuous_colors()
        Scale.color_continuous(
          colormap=Scale.lab_gradient(fgcol4, fgcol2, fgcol1)
        )
    end

    Theme(
          default_color=fgcol1,
          stroke_color=default_stroke_color,
          panel_fill=bgcolor,
          major_label_color=label_color,
          minor_label_color=label_color,
          grid_color=grid_color,
          key_title_color=label_color,
          key_label_color=label_color,
          lowlight_color=lowlight_color,
          background_color=bgcolor,
          discrete_highlight_color=border_color,
          discrete_color_scale=dark_theme_discrete_colors(),
          continuous_color_scale=dark_theme_continuous_colors(),
    )
end

"""
    get_theme(::Val{:dark})

A light foreground on a dark background.
"""
get_theme(::Val{:dark}) = dark_theme
