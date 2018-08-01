using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)
p1 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point,
          layer(xmin=[5.0, 7.0], xmax=[6.5, 8.0] , Geom.vband(color="green")))
p2 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point,
          layer(ymin=[2.5, 3.6], ymax=[3.0, 4.0], Geom.hband(color="red")))
hstack(p1,p2)
