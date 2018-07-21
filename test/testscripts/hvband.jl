using Gadfly

set_default_plot_size(6inch, 3inch)

layer_data = layer(x=collect(1:10), y=collect(1:10), Geom.point)

plot_hvbands = hstack(
    # plot(layer_data, layer(xintercept=[4], Geom.vline)),
    plot(layer_data, layer(xmin=[2], xmax=[4], Geom.vband(color="green")), layer(xmin=[6], xmax=[6.5], Geom.vband)),
    plot(layer_data, layer(ymin=[2,6], ymax=[4,6.5], Geom.hband(color="red"))))
