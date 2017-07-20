using Gadfly, Compose

set_default_plot_size(4inch,9inch)

p=plot(y=[1,2,3], Geom.line)
c=Compose.context()
vstack(Union{Plot,Compose.Context}[p,c,p,c,p])
