using Gadfly
set_default_plot_size(21cm, 8cm)

p1 = plot(x=collect(1:9), y=collect(1:9), Geom.point,
          layer(xmin=[5.0, 7.0], xmax=[6.5, 8.0] , Geom.vband, Theme(default_color="green")));

p2 = plot(x=collect(1:9), y=collect(1:9), Geom.point,
          layer(ymin=[2.5, 3.6], ymax=[3.0, 4.0], Geom.hband, Theme(default_color="red")));

hstack(p1, p2)
