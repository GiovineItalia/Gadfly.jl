
# Parameters controlling how a plot appears

load("Compose.jl")
using Compose


type Theme
    panel_background::ColorOrNothing
    panel_stroke::ColorOrNothing
    panel_padding::Measure
    grid_color::ColorOrNothing
    tick_label_font::String
    tick_label_font_size::Measure
    tick_label_color::ColorOrNothing
    axis_label_font::String
    axis_label_font_size::Measure
    axis_label_color::ColorOrNothing
    bar_width_scale::Maybe(Float64)

    # Points, etc, are highlighted by stroking in slightly different color. This
    # is the stroke width.
    highlight_width::Maybe(Measure)

    # A function mapping fill color to stoke color.
    stroke_color::Maybe(Function)
end


# Choose stroke color by darkening the fill color
function default_stroke_color(fill_color::Color)
    fill_color = convert(LCHab, fill_color)
    c = LCHab(fill_color.l, fill_color.c, fill_color.h)
    c.l -= 15
    c
end


const default_theme =
    Theme(
          color("#f5f5f5"),
          color("#f5f5f5"),
          1mm,
          color("#fdfdff"),
          "PT Sans Caption",
          10pt,
          color("#4c404b"),
          "PT Sans",
          12pt,
          color("#362a35"),
          0.9,
          0.3mm,
          default_stroke_color)
