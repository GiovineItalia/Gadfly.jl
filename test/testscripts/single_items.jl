using Dates, Gadfly

set_default_plot_size(6inch, 3inch)

# single_datetime, single_boxplot, single_violin

p1 = plot(x=[unix2datetime(100)], y=[10], Geom.point)
p2 = plot(y=randn(100), Geom.boxplot)
p3 = plot(y=randn(100), Geom.violin)

hstack(p1, p2, p3)