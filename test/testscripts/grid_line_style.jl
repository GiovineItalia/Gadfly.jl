using Gadfly

set_default_plot_size(14cm, 10cm)

plot(x=[5100, 5400], y=[0, 1], Geom.blank,
    Guide.yticks(ticks=0:0.1:1),
    Theme(grid_line_style=:solid, grid_line_width=0.5mm,
        grid_color="gray92", panel_stroke="black", 
        grid_line_order=-2,  panel_line_width=1mm)
)

