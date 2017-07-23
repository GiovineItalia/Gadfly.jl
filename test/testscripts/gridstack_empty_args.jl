using Gadfly, Compose

set_default_plot_size(8inch,6inch)

p=plot(y=[1,2,3], Geom.line)
c=Compose.context()
gridstack(Union{Plot,Compose.Context}[p c; c p])
