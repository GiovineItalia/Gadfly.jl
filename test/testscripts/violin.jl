using Gadfly, RDatasets

set_default_plot_size(6inch, 3inch)

plot(dataset("lattice", "singer"), x=:VoicePart, y=:Height, color=:VoicePart, Geom.violin)
