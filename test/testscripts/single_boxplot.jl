using Gadfly, Distributions

set_default_plot_size(6inch, 3inch)

plot(y=rand(Normal(), 100), Geom.boxplot)
