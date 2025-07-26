

using  Gadfly

set_default_plot_size(6inch, 6inch)


x= 1:10
s = [-1,-1,1,1,-1,-1,1,1,-1,-1]
pa = plot(x=x, y=x.^2, Geom.hair, Geom.point)
pb = plot(x=s.*(x.^2), y=x, Geom.hair(orientation=:horizontal), Geom.point, color=string.(s), Theme(key_position=:none))
pc = plot(x=x, y=x.^2, Geom.hair(intercept=(x.^2)./2), Geom.point)
pd = plot(x=s.*(x.^2), y=x, color=string.(s),
          Geom.hair(orientation=:horizontal, intercept=s.*(x.^2)/2), Geom.point, 
          Theme(key_position=:none))
gridstack([pa pb; pc pd])


