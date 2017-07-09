using Gadfly, Compose

set_default_plot_size(6inch, 3inch)

p1 = plot(x=[1,2,3], y=[4,5,6], Geom.point);
p2 = plot(x=[1,2,3], y=[4,5,6], Geom.line);
title(vstack(p1,p2), "foo", font("helvetica"))
