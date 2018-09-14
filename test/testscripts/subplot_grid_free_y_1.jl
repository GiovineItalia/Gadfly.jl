using Gadfly, RDatasets, Compat

set_default_plot_size(15cm, 15cm)

d = dataset("mlmRev", "Chem97")
idx = findall((d[:Score] .> 4) .& (d[:Age] .> 0))
plot(d[idx[1:4:end], :],
     x=:GCSEScore,
     ygroup=:Gender,
     xgroup=:Score,
     y=:Age,
     Geom.subplot_grid(Geom.point, free_y_axis=true),
     Theme(point_size=0.1mm, highlight_width=0.0mm))
