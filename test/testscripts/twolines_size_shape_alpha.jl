using Gadfly

set_default_plot_size(12inch, 3inch)

p_size = plot(x=[1,2,3,1,2,3], y=[1,2,3,4,5,6], size=[1,1,1,2,2,2],
              Geom.line, Geom.point, Scale.size_discrete2(n->range(3pt, 8pt, length=n)))
p_shape = plot(x=[1,2,3,1,2,3], y=[1,2,3,4,5,6], shape=[1,1,1,2,2,2],
               Geom.line, Geom.point)
p_alpha = plot(x=[1,2,3,1,2,3], y=[1,2,3,4,5,6], alpha=[1,1,1,0.5,0.5,0.5],
               Geom.line, Geom.point)

hstack(p_size, p_shape, p_alpha)
