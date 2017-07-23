using Gadfly, Compose

set_default_plot_size(12inch,3inch)

p=plot(y=[1,2,3], Geom.line)
c=Compose.context()
hstack(p,c,p,c,p)
