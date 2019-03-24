using Gadfly
set_default_plot_size(21cm, 8cm)

p1 = plot(xmin=[1.0, 5.0, 7.0], xmax=[2.0, 6.5, 8.0] , Geom.vband, Theme(default_color="green"));

p2 = plot(ymin=[2.5], ymax=[7.5], Geom.hband, Theme(default_color="red"));

hstack(p1, p2)
