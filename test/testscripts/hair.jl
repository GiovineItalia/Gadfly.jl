

using  Gadfly

set_default_plot_size(6inch, 3inch)


x= 1:10
s = [-1,-1,1,1,-1,-1,1,1,-1,-1]
pa = plot(x=x, y=x.^2, Geom.hair, Geom.point)
pb = plot(x=s.*(x.^2), y=x, Geom.hair(orientation=:horizontal), Geom.point, color=string.(s), Theme(key_position=:none))
hstack(pa, pb)


