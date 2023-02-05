using Gadfly, RDatasets

set_default_plot_size(6inch, 9inch)

df = dataset("lattice", "singer")

pplain = plot(df, x=:VoicePart, y=:Height, Geom.violin);
pcolored = plot(df, x=:VoicePart, y=:Height, color=:VoicePart, Geom.violin);

sort!(df, [:VoicePart], by=x->convert(String,x))
psorted = plot(df, x=:VoicePart, y=:Height, color=:VoicePart, Geom.violin);

vstack(pplain, pcolored, psorted)
