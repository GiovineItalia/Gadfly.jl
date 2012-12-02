
# Parameters controlling how a plot appears

load("Gadfly/src/misc.jl")


type Theme
    panel_background::ColorOrNothing
    panel_padding::Measure
    grid_color::ColorOrNothing
    tick_label_font::String
    tick_label_font_size::Measure
    tick_label_color::ColorOrNothing
    axis_label_font::String
    axis_label_font_size::Measure
    axis_label_color::ColorOrNothing
    bar_width_scale::Maybe(Float64)
end


const default_theme =
    Theme(color("grey95"),
          1mm,
          color("white"),
          "Helvetica",
          10pt,
          "grey30",
          "Helvetica",
          12pt,
          "grey30",
          0.9)
