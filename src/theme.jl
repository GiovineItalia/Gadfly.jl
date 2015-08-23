
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

@varset Theme begin
    # If the color aesthetic is not mapped to anything, this is the color that
    # is used.
    default_color,         ColorOrNothing,  LCHab(70, 60, 240)

    # Default size when the size aesthetic is not mapped.
    default_point_size,    Measure,         0.9mm

    # Width of lines in the line geometry.
    line_width,            Measure,         0.3mm

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
    minor_label_font,      String,          label_font_desc
    minor_label_font_size, Measure,         8pt
    minor_label_color,     ColorOrNothing,  colorant"#6c606b"

    # Font name, size and color used for axis labels, key title, etc.
    major_label_font,      String,          title_font_desc
    major_label_font_size, Measure,         11pt
    major_label_color,     ColorOrNothing,  colorant"#564a55"

    # Font name, size and color used for labels on plot elements.
    point_label_font,      String,          label_font_desc
    point_label_font_size, Measure,         8pt
    point_label_color,     ColorOrNothing,  colorant"#4c404b"

    # Font name, size and color used for key titles
    key_title_font,      String,          title_font_desc
    key_title_font_size, Measure,         11pt
    key_title_color,     ColorOrNothing,  colorant"#362a35"

    # Font name, size and color used for key entries.
    key_label_font,      String,          title_font_desc
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
    bar_highlight,         Union(Nothing, Function, Color),   nothing

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

end


const default_theme = Theme()

