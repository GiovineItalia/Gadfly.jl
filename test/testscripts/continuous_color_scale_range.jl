using Gadfly

set_default_plot_size(6inch, 3inch)

n = 10
plot(x=rand(n), y=rand(n), color=rand(n),
     Scale.color_continuous(minvalue=-10, maxvalue=10))
