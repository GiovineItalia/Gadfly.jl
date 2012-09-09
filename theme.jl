
# Parameters controlling how a plot appears


type Theme
    panel_background::ColorOrNothing
    panel_padding::Measure
    grid_color::ColorOrNothing
end


const default_theme =
    Theme(color("grey93"),
          1mm,
          color("grey98"))

