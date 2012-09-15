
# Parameters controlling how a plot appears

require("misc.jl")


type Theme
    panel_background::ColorOrNothing
    panel_padding::Measure
    grid_color::ColorOrNothing
    tick_label_font::String
    tick_label_font_size::Measure
    tick_label_color::ColorOrNothing
    bar_width_scale::Maybe(Float64)
end


const default_theme =
    Theme(color("grey95"),
          1mm,
          color("white"),
          "Questrial",
          10pt,
          "grey30",
          0.9)
