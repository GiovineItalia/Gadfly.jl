
# Parameters controlling how a plot appears

const default_font_desc = "'PT Sans','Helvetica Neue','Helvetica',sans-serif"


# Choose highlight color by darkening the fill color
function default_highlight_color(fill_color::ColorValue)
    fill_color = convert(LCHab, fill_color)
    c = LCHab(fill_color.l, fill_color.c, fill_color.h)
    LCHab(c.l - 15, c.c, c.h)
end


# Choose a middle color by darkening the fill color
function default_middle_color(fill_color::ColorValue)
    fill_color = convert(LCHab, fill_color)
    LCHab(fill_color.l + 40, fill_color.c, fill_color.h)
end


@varset Theme begin
    # If the color aesthetic is not mapped to anything, this is the color that
    # is used.
    default_color,         ColorOrNothing,  LCHab(70, 60, 240)

    # Default size when the size aesthetic is not mapped.
    default_point_size,    Measure,         0.6mm

    # Width of lines in the line geometry.
    line_width,            Measure,         0.3mm

    # Background color of the plot.
    panel_fill,            ColorOrNothing,  color("#fafafa")

    # Border color of the plot panel.
    panel_stroke,          ColorOrNothing,  color("#f1f1f5")

    # Grid line color.
    grid_color,            ColorOrNothing,  color("#f0f0f3")

    # Grid lines for focused item.
    grid_color_focused,    ColorOrNothing,  color("#f0f0f0")

    # Width of grid lines
    grid_line_width,       Measure,         0.2mm

    # Font name, size, and color used for tick labels, entries in keys, etc.
    minor_label_font,      String,          default_font_desc
    minor_label_font_size, Measure,         9pt
    minor_label_color,     ColorOrNothing,  color("#4c404b")

    # Font name, size and color used for axis labels, key title, etc.
    major_label_font,      String,          default_font_desc
    major_label_font_size, Measure,         11pt
    major_label_color,     ColorOrNothing,  color("#362a35")

    # Font name, size and color used for labels on plot elements.
    point_label_font,      String,          default_font_desc
    point_label_font_size, Measure,         8pt
    point_label_color,     ColorOrNothing,  color("#4c404b")

    # Spacing between bars for Geom.bar.
    bar_spacing,           Measure,         0.0mm

    # Spacing between boxplots in Geom.boxplot.
    boxplot_spacing,       Measure,         1mm

    # Length of caps on error bars
    errorbar_cap_length,   Measure,         3mm

    # Points, etc, are highlighted by stroking in slightly different color. This
    # is the stroke width.
    highlight_width,       Measure,         0.3mm

    # A function mapping fill color to stoke color for highlights.
    highlight_color,       Function,        default_highlight_color

    # A function mapping base fill color to the color of the median marker in a
    # boxplot.
    middle_color,          Function,        default_middle_color

    # Width of the middle line in a boxplot.
    middle_width,          Measure,         0.6mm

    # Horizontal position of the title of color key guides. One of :left,
    # :right, :center.
    guide_title_position,  Symbol,          :center

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

end


const default_theme = Theme()

