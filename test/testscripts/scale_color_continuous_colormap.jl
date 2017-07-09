using Gadfly, Colors

set_default_plot_size(6inch, 3inch)

x = repeat(collect(1:10), inner=[10])
y = repeat(collect(1:10), outer=[10])
plot(x=x, y=y, color=x+y, Geom.rectbin,
     Scale.color_continuous(colormap=p->RGB(0,p,0)))
