
# Parameters controlling how a plot appears


type Theme
    panel_background::ColorOrNothing
    panel_padding::Measure
    grid_color::ColorOrNothing
    tick_label_font::String
    tick_label_font_size::Measure
    tick_label_color::ColorOrNothing
end


const default_theme =
    Theme(color("grey95"),
          1mm,
          color("white"),
          "Questrial",
          10pt,
          "grey30")

