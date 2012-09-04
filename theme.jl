
# Parameters controlling how a plot appears


type Theme
    panel_background::ColorOrNothing
    panel_padding::Measure
end


const default_theme =
    Theme(color("grey90"),
          1mm)

