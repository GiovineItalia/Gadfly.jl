using Gadfly, RDatasets

set_default_plot_size(10cm, 15cm)

d=dataset("mlmRev", "Chem97")
idx = d[:Age] .>0
plot(d[idx,:],
     x=:GCSEScore,
     ygroup=:Age,
     color=:Gender,
     Geom.subplot_grid(Geom.histogram(bincount=20), free_y_axis=true))
