
# Parameters controlling how a plot appears

type Theme
    # If the color aesthetic is not mapped to anything, this is the color that
    # is used.
    default_color::ColorOrNothing

    # Default size when the size aesthetic is not mapped.
    default_point_size::Measure

    # Width of lines in the line geometry.
    line_width::Measure

    # Background color of the plot.
    panel_fill::ColorOrNothing

    # Border color of the plot panel.
    panel_stroke::ColorOrNothing

    # Grid line color.
    grid_color::ColorOrNothing

    # Width of grid lines
    grid_line_width::Measure

    # Font name, size, and color used for tick labels, entries in keys, etc.
    minor_label_font::String
    minor_label_font_size::Measure
    minor_label_color::ColorOrNothing

    # Font name, size and color used for axis labels, key title, etc.
    major_label_font::String
    major_label_font_size::Measure
    major_label_color::ColorOrNothing

    # Font name, size and color used for labels on plot elements.
    point_label_font::String
    point_label_font_size::Measure
    point_label_color::ColorOrNothing

    # Spacing between bars for Geom.bar.
    bar_spacing::Maybe(Measure)

    # Spacing between boxplots in Geom.boxplot.
    boxplot_spacing::Maybe(Measure)

    # Points, etc, are highlighted by stroking in slightly different color. This
    # is the stroke width.
    highlight_width::Maybe(Measure)

    # A function mapping fill color to stoke color for highlights.
    highlight_color::Maybe(Function)

    # A function mapping base fill color to the color of the median marker in a
    # boxplot.
    middle_color::Maybe(Function)

    # Number of annealing iterations.
    label_placement_iterations::Maybe(Int)

    # Penalty for a label not being contained within the plot frame.
    label_out_of_bounds_penalty::Maybe(Float64)

    # Penalty for making a label hidden to avoid overlaps.
    label_hidden_penalty::Maybe(Float64)

    # Probability of proposing a visibility flip during label layout.
    label_visibility_flip_pr::Maybe(Float64)
end


# Choose highlight color by darkening the fill color
function default_highlight_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    c = LCHab(fill_color.l, fill_color.c, fill_color.h)
    c.l -= 15
    c
end


# Choose a middle color by darkening the fill color
function default_middle_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    c = LCHab(fill_color.l, fill_color.c, fill_color.h)
    c.l += 40
    c
end


const default_theme =
    Theme(color("steel blue"),      # default_color
          0.5mm,                    # default_point_size
          0.4mm,                    # line_width
          color("#f5f5f5"),         # panel_fill
          color("#f2f2f2"),         # panel_stroke
          color("white"),           # grid_color
          0.3mm,                    # grid line width
          "PT Sans Caption",        # minor_label_font
          9pt,                      # minor_label_font_size
          color("#4c404b"),         # minor_label_color
          "PT Sans",                # major_label_font
          11pt,                     # major_label_font_size
          color("#362a35"),         # major_label_color
          "PT Sans",                # point_label_font
          8pt,                      # point_label_font_size
          color("#4c404b"),         # point_label_color
          -0.2mm,                   # bar_spacing
          1mm,                    # boxplot_spacing
          0.3mm,                    # highlight_width
          default_highlight_color,  # highlight_color
          default_middle_color,     # middle_color
          5000,                     # label_placement_iterations
          10.0,                     # label_out_of_bounds_penalty
          0.5,                      # label_hidden_penalty
          0.2)                      # label_visibility_flip_pr

