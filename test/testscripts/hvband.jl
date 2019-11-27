using Gadfly
set_default_plot_size(21cm, 8cm)

p1 = plot(xmin=[1.0, 5.0, 7.0], xmax=[2.0, 6.5, 8.0] , Geom.vband, Theme(default_color="green"));

p2 = plot(ymin=[2.5], ymax=[7.5], Geom.hband, Theme(default_color="red"));

p3 = plot(
    layer(Geom.band, xmin=[.25], xmax=[.75], Theme(default_color="red")),
    layer(Geom.rect, xmin=[0], xmax=[1], ymin=[0], ymax=[1], Theme(default_color="blue"))
) # Note: Covers function apply_statistic_typed.

hstack(p1, p2, p3)
