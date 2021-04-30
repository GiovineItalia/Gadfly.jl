using DataFrames, Gadfly
import Compose: w, h

set_default_plot_size(12inch,3.3inch)

# Issue #1357

df = DataFrame(x=[0.6w, 0.6w], y=[0.6h, 0.7h], label=["Text 1", "Text 2"])
lyr1 = layer(x=1.0:5, y=[0.21, 0.81, 0.68, 0.76, 0.18], Geom.point)
lyr2 = layer(df, x=:x, y=:y, label=:label, Geom.label(position=:right))
lyr3 = layer(xintercept=[0.5inch], Geom.vline(color="orange"))

p1 = plot(xmin=[.25], xmax=[.75], Geom.band, color=[colorant"red"])
p2 = plot(xmin=[.25], xmax=[.75], Geom.band, color=[colorant"red"],
    layer(Geom.rect, xmin=[0], xmax=[1], ymin=[0], ymax=[1], color=[colorant"blue"]))
p3 = plot(lyr1, lyr2, lyr3)
p4 = plot(lyr1, lyr2, lyr3, Scale.x_discrete)
    

hstack(p1, p2, p3, p4)

