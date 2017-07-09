using Gadfly

set_default_plot_size(6inch, 3inch)

n = 10
plot(x=rand(n), y=rand(n),
     Scale.x_continuous(minvalue=-10, maxvalue=10),
     Scale.y_continuous(minvalue=-10, maxvalue=10))
