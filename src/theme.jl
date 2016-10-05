
# Parameters controlling how a plot appears

const title_font_desc = "'PT Sans','Helvetica Neue','Helvetica',sans-serif"
const label_font_desc = "'PT Sans Caption','Helvetica Neue','Helvetica',sans-serif"

# Choose highlight color by darkening the fill color
function default_discrete_highlight_color(fill_color::Color)
    return RGB(1, 1, 1)
end

function default_discrete_highlight_color(fill_color::TransparentColor)
    return RGBA{Float32}(
        default_discrete_highlight_color(color(fill_color)),
        fill_color.alpha)
end

function default_continuous_highlight_color(fill_color::Color)
    c = convert(LCHab, fill_color)
    return LCHab(max(0, c.l - 40), c.c, c.h)
end

function default_continuous_highlight_color(fill_color::TransparentColor)
    return RGBA{Float32}(
        default_continuous_highlight_color(color(fill_color)),
        fill_color.alpha)
end

function default_stroke_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    c = LCHab(fill_color.l, fill_color.c, fill_color.h)
    LCHab(c.l - 15, c.c, c.h)
end

function default_stroke_color(fill_color::TransparentColor)
    return RGBA{Float32}(
        default_stroke_color(color(fill_color)),
        fill_color.alpha)
end

function default_lowlight_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    c = LCHab(fill_color.l, fill_color.c, fill_color.h)
    LCHab(90, 20, c.h)
end

function default_lowlight_color(fill_color::TransparentColor)
    return RGBA{Float32}(
        default_lowlight_color(color(fill_color)),
        fill_color.alpha)
end

# Choose a middle color by darkening the fill color
function default_middle_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    LCHab(fill_color.l + 40, fill_color.c, fill_color.h)
end

function default_middle_color(fill_color::TransparentColor)
    return RGBA{Float32}(
        default_middle_color(color(fill_color)),
        fill_color.alpha)
end

 
get_stroke_vector(::@compat(Void)) = []
get_stroke_vector(vec::AbstractVector) = vec
function get_stroke_vector(linestyle::Symbol)
  dash = 12 * Compose.mm
  dot = 3 * Compose.mm
  gap = 2 * Compose.mm
  linestyle == :solid && return []
  linestyle == :dash && return [dash, gap]
  linestyle == :dot && return [dot, gap]
  linestyle == :dashdot && return [dash, gap, dot, gap]
  linestyle == :dashdotdot && return [dash, gap, dot, gap, dot, gap]
  error("unsupported linestyle: ", linestyle)
end


@varset Theme begin
    # If the color aesthetic is not mapped to anything, this is the color that
    # is used.
    default_color,         ColorOrNothing,  LCHab(70, 60, 240)

    # Default size when the size aesthetic is not mapped.
    default_point_size,    Measure,         0.9mm

    # Width of lines in the line geometry.
    line_width,            Measure,         0.3mm

    # type of dash style (a Compose.StrokeDash object which takes a vector of sold/missing/solid/missing/... 
    # lengths which are applied cyclically)
    line_style,            Maybe(Vector),   nothing

    # Background color of the plot.
    panel_fill,            ColorOrNothing,  nothing

    # Border color of the plot panel.
    panel_stroke,          ColorOrNothing,  nothing

    # Opacity of the plot background panel.
    panel_opacity,         Float64,         1.0

    # Background of the entire plot
    background_color,      ColorOrNothing,  nothing

    # Padding around the entire plot
    plot_padding,          Measure,         5mm

    # Grid line color.
    grid_color,            ColorOrNothing,  colorant"#D0D0E0"
    grid_strokedash,       Maybe(Vector),   [0.5mm, 0.5mm]

    # Grid lines for focused item.
    grid_color_focused,    ColorOrNothing,  colorant"#A0A0A0"

    # Width of grid lines
    grid_line_width,       Measure,         0.2mm

    # Font name, size, and color used for tick labels, entries in keys, etc.
    minor_label_font,      AbstractString,          label_font_desc
    minor_label_font_size, Measure,         8pt
    minor_label_color,     ColorOrNothing,  colorant"#6c606b"

    # Font name, size and color used for axis labels, key title, etc.
    major_label_font,      AbstractString,          title_font_desc
    major_label_font_size, Measure,         11pt
    major_label_color,     ColorOrNothing,  colorant"#564a55"

    # Font name, size and color used for labels on plot elements.
    point_label_font,      AbstractString,          label_font_desc
    point_label_font_size, Measure,         8pt
    point_label_color,     ColorOrNothing,  colorant"#4c404b"

    # Font name, size and color used for key titles
    key_title_font,      AbstractString,          title_font_desc
    key_title_font_size, Measure,         11pt
    key_title_color,     ColorOrNothing,  colorant"#362a35"

    # Font name, size and color used for key entries.
    key_label_font,      AbstractString,          title_font_desc
    key_label_font_size, Measure,         8pt
    key_label_color,     ColorOrNothing,  colorant"#4c404b"

    # How many gradations to show in a continuous color key.
    key_color_gradations, Int,            40

    # Spacing between bars for Geom.bar.
    bar_spacing,           Measure,         -0.05mm

    # Spacing between boxplots in Geom.boxplot.
    boxplot_spacing,       Measure,         1mm

    # Length of caps on error bars
    errorbar_cap_length,   Measure,         3mm

    # Lines are drawn in a slightly different color than fills, e.g. to
    # differentiate histogram bars from error bars.
    stroke_color,          Function,       default_stroke_color

    # Points, etc, are highlighted by stroking in slightly different color. This
    # is the stroke width.
    highlight_width,       Measure,         0.3mm

    # A function mapping fill color to stoke color for highlights.
    discrete_highlight_color,       Function,        default_discrete_highlight_color
    continuous_highlight_color,     Function,        default_continuous_highlight_color

    # A function mapping fill color to a duller background fill color. Used for
    # Geom.ribbon in particular so lines stand out against it.
    lowlight_color,        Function,        default_lowlight_color

    # Opacity of geometry filled with lowlight_color
    lowlight_opacity,      Float64,         0.6

    # A function mapping base fill color to the color of the median marker in a
    # boxplot.
    middle_color,          Function,        default_middle_color

    # Width of the middle line in a boxplot.
    middle_width,          Measure,         0.6mm

    # Horizontal position of the title of color key guides. One of :left,
    # :right, :center.
    guide_title_position,  Symbol,          :left

    # Shape used in color keys for color swatches. Either :square or :circle.
    colorkey_swatch_shape, Symbol,          :square

    # One of :left, :right, :top, :bottom, :none determining where color keys
    # and the like should be placed.
    key_position,          Symbol,          :right

    # True if bars in bar plots should be stroked. Stroke color is
    bar_highlight,         @compat(Union{(@compat Void), Function, Color}),   nothing

    # Symbol forms used for the shape aesthetic
    shapes,               Vector{Function},  [circle, square, diamond, cross,
                                              xcross, utriangle, dtriangle,
                                              star1, star2, hexagon, octagon]

    rug_size,             Measure,          2.0mm

    # TODO: This stuff is too incomprehensible to be in theme, I think. Put it
    # somewhere else.

    # Number of annealing iterations.
    label_placement_iterations,  Int,       1000

    # Penalty for a label not being contained within the plot frame.
    label_out_of_bounds_penalty, Float64,   10.0

    # Penalty for making a label hidden to avoid overlaps.
    label_hidden_penalty,        Float64,   0.5

    # Probability of proposing a visibility flip during label layout.
    label_visibility_flip_pr,    Float64,   0.2

    # Number of columns in key
    key_max_columns,             Int,       4

    # Discrete color scale
    discrete_color_scale,        Scale.DiscreteColorScale, Scale.color_discrete()

    # Continuous color scale
    continuous_color_scale,      Scale.ContinuousColorScale, Scale.color_continuous()

end


const theme_stack = Theme[Theme()]

"""
Get Theme on top of the theme stack
"""
current_theme() = theme_stack[end]


"""
Set some attributes in the current `Theme`.
See `Theme` for available field.
"""
style(; kwargs...) = Theme(current_theme(); kwargs...)


"""
Set the current theme. Pushes the theme to a stack. You can pop it using `pop_theme`.

You can use this in conjunction with `style` to
set a subset of Theme attributes.

    push_theme(style(background_color=colorant"#888888")))

See also `with_theme`
"""
function push_theme(t::Theme)
    push!(theme_stack, t)
    nothing
end


"""
Go back to using the previous theme

See also `push_theme` and `with_theme`
"""
function pop_theme()
    if length(theme_stack) == 1
        error("There default theme cannot be removed")
    end

    pop!(theme_stack)
end


"""
Push a theme by its name. Available options are `:default` and `:dark`.

A new theme can be added by adding a method to `get_theme`

    get_theme(::Val{:mytheme}) = Theme(...)

    push_theme(:mytheme) # will set the above theme
"""
function push_theme(t::Symbol)
    push_theme(get_theme(Val{t}()))
end


"""
Register a theme by name.

    get_theme(::Val{:mytheme}) = Theme(...)

    push_theme(:mytheme) # will set the above theme

See also: push_theme, with_theme
"""
function get_theme{name}(::Val{name})
    error("No theme $name found")
end


"""
Call a function after setting a new theme.

Theme can be a `Theme` object or a symbol.

You can use this in conjunction with `style` to
set a subset of Theme attributes.

    with_theme(style(background_color=colorant"#888888"))) do
        plot(x=rand(10), y=rand(10))
    end
"""
function with_theme(f, theme)
    push_theme(theme)
    p = f()
    pop_theme()
    p
end

function get_theme(::Val{:default})
    Theme()
end

### Override default getters for color scales

function get_scale(::Val{:categorical}, ::Val{:color}, theme::Theme=current_theme())
    theme.discrete_color_scale
end


function get_scale(::Val{:numerical}, ::Val{:color}, theme::Theme=current_theme())
    theme.continuous_color_scale
end


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

function get_theme(::Val{:dark})
    dark_theme
end
